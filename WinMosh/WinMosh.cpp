// WinMosh.cpp : Defines the class behaviors for the application.
//

#include "stdafx.h"
#include "WinMosh.h"

#include "MainFrm.h"
#include <atlbase.h>
#ifdef _DEBUG
#define new DEBUG_NEW
#undef THIS_FILE
static char THIS_FILE[] = __FILE__;
#endif

/////////////////////////////////////////////////////////////////////////////
// CWinMoshApp

BEGIN_MESSAGE_MAP(CWinMoshApp, CWinApp)
	//{{AFX_MSG_MAP(CWinMoshApp)
	ON_COMMAND(ID_APP_ABOUT, OnAppAbout)
		// NOTE - the ClassWizard will add and remove mapping macros here.
		//    DO NOT EDIT what you see in these blocks of generated code!
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

/////////////////////////////////////////////////////////////////////////////
// CWinMoshApp construction

CWinMoshApp::CWinMoshApp()
{
	// TODO: add construction code here,
	// Place all significant initialization in InitInstance
}

/////////////////////////////////////////////////////////////////////////////
// The one and only CWinMoshApp object

CWinMoshApp theApp;

/////////////////////////////////////////////////////////////////////////////
// CWinMoshApp initialization

BOOL CWinMoshApp::InitInstance()
{
	CString moshhome;
	CString ModelicaPath;
	if (!moshhome.GetEnvironmentVariable("MOSHHOME") || moshhome == "") {
		moshhome = theApp.m_pszHelpFilePath;
		moshhome = moshhome.Left(moshhome.ReverseFind('\\'));
		SetEnvironmentVariable("MOSHHOME", moshhome);
		CString msg;
		msg.Format("MOSHOME Environment variable not set. Using default: %s", (LPCSTR)moshhome);
		MessageBox(NULL, msg, "Environment varible not set", MB_ICONWARNING|MB_OK);
	}
	if (!ModelicaPath.GetEnvironmentVariable("MODELICAPATH") || ModelicaPath == "") {
		ModelicaPath = moshhome;
		if (ModelicaPath.Right(1) == "\\") 
			ModelicaPath = ModelicaPath.Left(ModelicaPath.GetLength() -1);
		ModelicaPath = ModelicaPath.Left(ModelicaPath.ReverseFind('\\'));
		ModelicaPath += "\\ModelicaLibrary";
		SetEnvironmentVariable("MODELICAPATH", ModelicaPath);
		CString msg;
		msg.Format("MODELICAPATH Environment variable not set. Using default: %s", (LPCSTR)ModelicaPath);
		MessageBox(NULL, msg, "Environment varible not set", MB_ICONWARNING|MB_OK);
	}

	// To create the main window, this code creates a new frame window
	// object and then sets it as the application's main window object.

	CMainFrame* pFrame = new CMainFrame;
	m_pMainWnd = pFrame;

	// create and load the frame with its resources

	pFrame->LoadFrame(IDR_MAINFRAME,
		WS_OVERLAPPEDWINDOW | FWS_ADDTOTITLE, NULL,
		NULL);

	CString cmdLine = m_lpCmdLine;
	int curpos = 0;
	CString opt;
	opt = cmdLine.Tokenize(" \t",curpos);
	while (opt != "") {
		if (opt.CompareNoCase("-noserv") == 0) {
			pFrame->m_wndView.SetNoServ();
		}
		if (opt.CompareNoCase("-showserv") == 0) {
			pFrame->m_wndView.SetShowServ();
		}
		opt = cmdLine.Tokenize(" \t",curpos);
	}
	
	// always show server since it keeps popping up new consoles otherwise
	pFrame->m_wndView.SetShowServ(); 

	// The one and only window has been initialized, so show and update it.
	pFrame->ShowWindow(SW_SHOW);
	pFrame->UpdateWindow();

	return TRUE;
}

/////////////////////////////////////////////////////////////////////////////
// CWinMoshApp message handlers





/////////////////////////////////////////////////////////////////////////////
// CAboutDlg dialog used for App About

class CAboutDlg : public CDialog
{
public:
	CAboutDlg();

// Dialog Data
	//{{AFX_DATA(CAboutDlg)
	enum { IDD = IDD_ABOUTBOX };
	//}}AFX_DATA

	// ClassWizard generated virtual function overrides
	//{{AFX_VIRTUAL(CAboutDlg)
	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	//}}AFX_VIRTUAL

// Implementation
protected:
	//{{AFX_MSG(CAboutDlg)
		// No message handlers
	//}}AFX_MSG
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD)
{
	//{{AFX_DATA_INIT(CAboutDlg)
	//}}AFX_DATA_INIT
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	//{{AFX_DATA_MAP(CAboutDlg)
	//}}AFX_DATA_MAP
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)
	//{{AFX_MSG_MAP(CAboutDlg)
		// No message handlers
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

// App command to run the dialog
void CWinMoshApp::OnAppAbout()
{
	CAboutDlg aboutDlg;
	aboutDlg.DoModal();
}

/////////////////////////////////////////////////////////////////////////////
// CWinMoshApp message handlers

