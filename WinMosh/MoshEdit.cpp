// MoshEdit.cpp : implementation file
//

#include "stdafx.h"
#include "WinMosh.h"
#include "MoshEdit.h"

#include <sstream>
#include <process.h>

#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

extern CWinMoshApp theApp; 

/////////////////////////////////////////////////////////////////////////////
// CMoshEdit

CMoshEdit::CMoshEdit()
{
	m_History.LoadHistory("mosh_history");
	StartServer();
}

CMoshEdit::~CMoshEdit()
{
	try {
		if (client != NULL) {
			char* tmp = client->sendExpression("quit()");
			CORBA::string_free(tmp);
		}
	}
	catch(CORBA::Exception e) {
	}
	m_History.SaveHistory("mosh_history");
}


BEGIN_MESSAGE_MAP(CMoshEdit, CEdit)
	//{{AFX_MSG_MAP(CMoshEdit)
	ON_WM_KEYUP()
	ON_WM_LBUTTONDOWN()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CMoshEdit message handlers


void CMoshEdit::OnKeyUp(UINT nChar, UINT nRepCnt, UINT nFlags) 
{
	if (nChar == VK_UP) {
		CString line = m_History.GetPrev();

		CString txt;
		GetWindowText(txt);
		int indexOfRowStart = txt.ReverseFind('\n') + 1;
		txt = txt.Left(indexOfRowStart+3) + line;
		SetWindowText(txt);
		SetSel(txt.GetLength(),txt.GetLength());
	}
	else if (nChar == VK_DOWN) {
		CString line = m_History.GetNext();

		CString txt;
		GetWindowText(txt);
		int indexOfRowStart = txt.ReverseFind('\n') + 1;
		txt = txt.Left(indexOfRowStart+3) + line;
		SetWindowText(txt);
		SetSel(txt.GetLength(),txt.GetLength());
	}
	else if (nChar == 13) {
		CString res;
		int start, end;
		GetSel(start,end);
		int line = LineFromChar(start-1);
		int linelength = LineLength(start-1);
		CString command;
		LPTSTR buf = command.GetBuffer(linelength+1);
		GetLine(line,buf,linelength);
		buf[linelength] = 0;
		command.ReleaseBuffer();

		if (command.Left(3) == ">> ")
			res = DoCommand(command.Mid(3));

		CString txt;
		GetWindowText(txt);
		txt += res + "\r\n";
		txt += ">> ";
		SetWindowText(txt);
		SetSel(txt.GetLength(),txt.GetLength());
	}
	else if (nChar == VK_TAB) {
		int start, end;
		GetSel(start,end);
		if (end > start)
			SetSel(end,end);
	}

	int lastline = GetLineCount() - 1;
	int currentline = LineFromChar();
	if (currentline != lastline) {
		SetSel(LineIndex(lastline)+3,LineIndex(lastline)+3);
	}
	CEdit::OnKeyUp(nChar, nRepCnt, nFlags);
}


CString CMoshEdit::DoCommand(LPCTSTR command)
{
	m_History.AddEntry(command);
	if (client == NULL)
		return CString("No Server");

	try {
		if (CString(command) == "quit()") {
			theApp.GetMainWnd()->PostMessage(WM_CLOSE);
		}
		char* tmp = client->sendExpression(command);
		CString res = tmp;
		CORBA::string_free(tmp);

		res.Replace("\n","\r\n");
		return res;
	}
	catch(CORBA::Exception e) {
		std::ostringstream ss;
		e._print(ss);
//		AfxMessageBox(ss.str().c_str());
		client = NULL;
		return CString(ss.str().c_str());
	}
}

BOOL CMoshEdit::PreTranslateMessage(MSG* pMsg) 
{
	int start, end;


	if (pMsg->message == WM_KEYDOWN) {
		int key = pMsg->wParam;
		switch (key) {
		case VK_UP:
			return TRUE;
			break;
		case VK_DOWN:
			return TRUE;
			break;
		case VK_LEFT:
			GetSel(start, end);
			if ((start - LineIndex()) <= 3)
				return TRUE;
			break;
		case VK_TAB:
			GetSel(start, end);
			if (end > start)
				return TRUE;
		default:
			GetSel(start, end);
			if ((start - LineIndex(GetLineCount()-1)) < 3)
				return TRUE;
			break;
		}

	}
	return CEdit::PreTranslateMessage(pMsg);
}

void CMoshEdit::OnLButtonDown(UINT nFlags, CPoint point) 
{
	// TODO: Add your message handler code here and/or call default
	
	CEdit::OnLButtonDown(nFlags, point);
}

bool CMoshEdit::StartServer(void)
{
	WIN32_FIND_DATA data;
	char tmpPath[1025];
	int argc = 0;
	char argv[10][2];
	sprintf(argv[0], "WinMosh");
	orb = CORBA::ORB_init(argc,(char**)argv);
	char uri[300];
	GetTempPath(1024,tmpPath);

	sprintf(uri, "%sopenmodelica.objid",tmpPath);
	HANDLE hFile = FindFirstFile(uri,&data);
	if (hFile == INVALID_HANDLE_VALUE) {
		SpawnServer();
	}
	else {
		FindClose(hFile);
	}

	sprintf(uri, "file://%sopenmodelica.objid",tmpPath);
	CString sUri = uri;
	sUri.Replace("\\","/");

	bool notStarted = true;
	int count = 0;
	while (notStarted && count < 10) {
		try {
			CORBA::Object_var obj = orb->string_to_object(sUri);	
			client = ModeqCommunication::_narrow(obj);
			char *tmp = client->sendExpression("cd()");
			CORBA::string_free(tmp);
			notStarted = false;
		}
		catch(CORBA::Exception e) {
		}
		Sleep(500);
		count ++;
		if (count == 5)
			SpawnServer();
	}

	return !notStarted;
}

void CMoshEdit::SpawnServer(void)
{
	CString MoshHome;
	if (MoshHome.GetEnvironmentVariable("MOSHHOME")) {
		MoshHome += "\\..\\modeq\\win\\modeq";
		spawnl(_P_NOWAIT, MoshHome, MoshHome, "+d=interactiveCorba", NULL);
	}
}
