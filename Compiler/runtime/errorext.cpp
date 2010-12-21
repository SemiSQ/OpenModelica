/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include <iostream>
#include <fstream>
#include <queue>
#include <stack>
#include <list>
#include <string.h>
#include <stdlib.h>
#include <utility>
#include "rtopts.h"

using namespace std;


struct absyn_info{
  std::string fn;
  bool wr;
  int rs;
  int re;
  int cs;
  int ce;
};
// if error_on is true, message is added, otherwise not.
static bool error_on=true;
static int numErrorMessages=0;

#include "ErrorMessage.hpp"
static std::string currVariable("");
static absyn_info finfo;
static bool haveInfo(false);
static stack<ErrorMessage*> errorMessageQueue; // Global variable of all error messages.
static vector<pair<int,string> > checkPoints; // a checkpoint has a message index no, and a unique identifier
static string lastDeletedCheckpoint = "";

static void push_message(ErrorMessage *msg)
{
  if (showErrorMessages)
    std::cerr << msg->getFullMessage() << std::endl;
  else
    errorMessageQueue.push(msg);
  if (msg->getSeverity().compare(std::string("Error")) == 0) numErrorMessages++;
}

/* pop the top of the message stack (and any duplicate messages that have also been added) */
static void pop_message()
{
  ErrorMessage *msg = errorMessageQueue.top();
  if (msg->getSeverity().compare(std::string("Error")) == 0) numErrorMessages--;
  errorMessageQueue.pop();
  int pop_more = errorMessageQueue.size() > 0 && msg->getFullMessage() == errorMessageQueue.top()->getFullMessage();
  delete msg;
  if (pop_more)
    pop_message();
}

/* Adds a message without file info. */
extern void add_message(int errorID,
     const char* type,
     const char* severity,
     const char* message,
     std::list<std::string> tokens)
{
  std::string tmp("");
  if(currVariable.length()>0) {
    tmp = "Variable "+currVariable+": " +message;
  }
  else {
    tmp=message;
  }
  ErrorMessage *msg = haveInfo ?
    new ErrorMessage((long)errorID, std::string(type ), std::string(severity), tmp, tokens, finfo.rs,finfo.cs,finfo.re,finfo.ce,finfo.wr,finfo.fn) :
    new ErrorMessage((long)errorID, std::string(type ), std::string(severity), tmp, tokens);
  push_message(msg);
}

/* Adds a message with file information */
void add_source_message(int errorID,
      const char* type,
      const char* severity,
      const char* message,
      std::list<std::string> tokens,
      int startLine,
      int startCol,
      int endLine,
      int endCol,
      bool isReadOnly,
      const char* filename)
{
  ErrorMessage* msg = new ErrorMessage((long)errorID,
       std::string(type),
       std::string(severity),
       std::string(message),
       tokens,
       (long)startLine,
       (long)startCol,
       (long)endLine,
       (long)endCol,
       isReadOnly,
       std::string(filename));
  push_message(msg);
}

extern "C"
{

#include <assert.h>

/* sets the current_variable(which is beeing instantiated) */
extern void ErrorImpl__updateCurrentComponent(const char* newVar, int wr, const char* fn, int rs, int re, int cs, int ce)
{
  currVariable = std::string(newVar);
  if( (rs+re+cs+ce) > 0) {
    finfo.wr = wr;
    finfo.fn = fn;
    finfo.rs = rs;
    finfo.re = re;
    finfo.cs = cs;
    finfo.ce = ce;
    haveInfo = true;
  } else {
    haveInfo = false;
  }
}

static void printCheckpointStack(void)
{
  pair<int,string> cp;
  std::string res("");
  printf("Current Stack:\n");
  for (int i=checkPoints.size()-1; i>=0; i--)
  {
    cp = checkPoints[i];
    printf("%5d %s   message:", i, cp.second.c_str());
    while(errorMessageQueue.size() > cp.first && errorMessageQueue.size() > 0){
      res = errorMessageQueue.top()->getMessage()+string(" ")+res;
      pop_message();
    }
    printf("%s\n", res.c_str());
  }
}

extern void ErrorImpl__setCheckpoint(const char* id)
{
  checkPoints.push_back(make_pair(errorMessageQueue.size(),string(id)));
  // fprintf(stderr, "setCheckpoint(%s)\n",id); fflush(stderr);
  //printf(" ERROREXT: setting checkpoint: (%d,%s)\n",(int)errorMessageQueue.size(),id);
}
  
extern void ErrorImpl__delCheckpoint(const char* id)
{
  pair<int,string> cp;
  // fprintf(stderr, "delCheckpoint(%s)\n",id); fflush(stderr);
  if(checkPoints.size() > 0){
    //printf(" ERROREXT: deleting checkpoint: %d\n", checkPoints[checkPoints.size()-1]);

    // extract last checkpoint
    cp = checkPoints[checkPoints.size()-1];
    if (0 != strcmp(cp.second.c_str(),id)) {
      printf("ERROREXT: deleting checkpoint called with id:'%s' but top of checkpoint stack has id:'%s'\n",
          id,
          cp.second.c_str());
      printCheckpointStack();
      exit(-1);
    }
    // remember the last deleted checkpoint
    lastDeletedCheckpoint = cp.second;
    checkPoints.pop_back();
  }
  else{
    printf(" ERROREXT: nothing to delete when calling delCheckPoint(%s)\n",id);
    exit(-1);
  }
}

extern void ErrorImpl__rollBack(const char* id)
{
  // fprintf(stderr, "rollBack(%s)\n",id); fflush(stderr);
  if(checkPoints.size() > 0){
    //printf(" ERROREXT: rollback to: %d from %d\n",checkPoints.back(),errorMessageQueue.size());
    std::string res("");
    //printf(res.c_str());
    //printf(" rollback from: %d to: %d\n",errorMessageQueue.size(),checkPoints.back().first);
    while(errorMessageQueue.size() > checkPoints.back().first && errorMessageQueue.size() > 0){
      //printf("*** %d deleted %d ***\n",errorMessageQueue.size(),checkPoints.back().first);
      /*if(!errorMessageQueue.empty()){
        res = res+errorMessageQueue.top()->getMessage()+string("\n");
        printf( (string("Deleted: ") + res).c_str());
      }*/
      pop_message();
    }
    /*if(!errorMessageQueue.empty()){
      res = res+errorMessageQueue.top()->getMessage()+string("\n");
      printf("(%d)new bottom message: %s\n",checkPoints.size(),res.c_str());
    }*/
    pair<int,string> cp;
    cp = checkPoints[checkPoints.size()-1];
    if (0 != strcmp(cp.second.c_str(),id)) {
      printf("ERROREXT: rolling back checkpoint called with id:'%s' but top of checkpoint stack has id:'%s'\n",
          id,
          cp.second.c_str());
      printCheckpointStack();
      exit(-1);
    }
    checkPoints.pop_back();
  } else {
    printf("ERROREXT: caling rollback with id: %s on empty checkpoint stack\n",id);
      exit(-1);
    }
}

extern char* ErrorImpl__rollBackAndPrint(const char* id)
{
  std::string res("");
  // fprintf(stderr, "rollBackAndPrint(%s)\n",id); fflush(stderr);
  if(checkPoints.size() > 0){
    while(errorMessageQueue.size() > checkPoints.back().first && errorMessageQueue.size() > 0){
      res = errorMessageQueue.top()->getMessage()+string("\n")+res;
      pop_message();
    }
    pair<int,string> cp;
    cp = checkPoints[checkPoints.size()-1];
    if (0 != strcmp(cp.second.c_str(),id)) {
      printf("ERROREXT: rolling back checkpoint called with id:'%s' but top of checkpoint stack has id:'%s'\n",
          id,
          cp.second.c_str());
      printCheckpointStack();
      exit(-1);
    }
    checkPoints.pop_back();
  } else {
    printf("ERROREXT: caling rollback with id: %s on empty checkpoint stack\n",id);
      exit(-1);
  }
  // fprintf(stderr, "Returning %s\n", res.c_str());
  return strdup(res.c_str());
}

/*
 * @author: adrpo
 * checks to see if a checkpoint exists or not AS THE TOP of the stack!
 */
extern int ErrorImpl__isTopCheckpoint(const char* id)
{
  pair<int,string> cp;
  //printf("existsCheckpoint(%s)\n",id);
  if(checkPoints.size() > 0){
    //printf(" ERROREXT: searching checkpoint: %d\n", checkPoints[checkPoints.size()-1]);

    // search
    cp = checkPoints[checkPoints.size()-1];
    if (0 == strcmp(cp.second.c_str(),id))
    {
      // found our checkpoint, return true;
      return 1;
    }
  }
  // not found
  return 0;
}

/*
 * @author: adrpo
 * retrieves the last deleted checkpoint
 */
static const char* ErrorImpl__getLastDeletedCheckpoint()
{
  return lastDeletedCheckpoint.c_str();
}

extern void c_add_message(int errorID, const char* type, const char* severity, const char* message, const char** ctokens, int nTokens)
{
  std::list<std::string> tokens;
  for (int i=nTokens-1; i>=0; i--) {
    tokens.push_back(std::string(ctokens[i]));
  }
  add_message(errorID,type,severity,message,tokens);
}

extern void c_add_source_message(int errorID, const char* type, const char* severity, const char* message, const char** ctokens, int nTokens, int startLine, int startCol, int endLine, int endCol, int isReadOnly, const char* filename)
{
  std::list<std::string> tokens;
  for (int i=nTokens-1; i>=0; i--) {
    tokens.push_back(std::string(ctokens[i]));
  }
  add_source_message(errorID,type,severity,message,tokens,startLine,startCol,endLine,endCol,isReadOnly,filename);
}

extern int ErrorImpl__getNumErrorMessages() {
  return numErrorMessages;
}

extern void ErrorImpl__clearMessages()
{
  while(!errorMessageQueue.empty()) {
    pop_message();
  }
}

// TODO: Use a string builder instead of creating intermediate results all the time?
extern std::string ErrorImpl__getMessagesStr()
{
  std::string res("}");
  while(!errorMessageQueue.empty()) {
    res = errorMessageQueue.top()->getFullMessage() + res;
    pop_message();
    if (!errorMessageQueue.empty()) { res = string(",") + res; }
  }
  res = string("{") + res;
  return res;
}

// TODO: Use a string builder instead of creating intermediate results all the time?
extern std::string ErrorImpl__printMessagesStr()
{
  std::string res("");
  while(!errorMessageQueue.empty()) {
    res = errorMessageQueue.top()->getMessage()+string("\n")+res;
    pop_message();
  }
  return res;
}

}
