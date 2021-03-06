/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package ClassLoader
" file:        ClassLoader.mo
  package:     ClassLoader
  description: Loading of classes from $OPENMODELICALIBRARY.

  RCS: $Id$

  This module loads classes from $OPENMODELICALIBRARY. It exports several functions:
  loadClass function
  loadModel function
  loadFile function"

public import Absyn;
public import Interactive;

protected import Config;
protected import Debug;
protected import Flags;
protected import List;
protected import Parser;
protected import Print;
protected import System;
protected import Util;

public function loadClass
"function: loadClass
  This function takes a \'Path\' and the $OPENMODELICALIBRARY as a string
  and tries to load the class from the path.
  If the classname is qualified, the complete package is loaded.
  E.g. load_class(Modelica.SIunits.Voltage) -> whole Modelica package loaded."
  input Absyn.Path inPath;
  input list<String> priorityList;
  input String modelicaPath;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inPath,priorityList,modelicaPath)
    local
      String gd,classname,mp,pack;
      list<String> mps;
      Absyn.Program p;
      Absyn.Path rest,path;
      Absyn.TimeStamp ts;
    /* Simple names: Just load the file if it can be found in $OPENMODELICALIBRARY */
    case (Absyn.IDENT(name = classname),priorityList,mp)
      equation
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(classname, priorityList, mps);
      then
        p;
    /* Qualified names: First check if it is defined in a file pack.mo */
    case (Absyn.QUALIFIED(name = pack,path = rest),priorityList,mp)
      equation
        gd = System.groupDelimiter();
        mps = System.strtok(mp, gd);
        p = loadClassFromMps(pack, priorityList, mps);
      then
        p;
    /* failure */
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "ClassLoader.loadClass failed\n");
      then
        fail();
  end matchcontinue;
end loadClass;

protected function existRegularFile
"function: existRegularFile
  Checks if a file exists"
  input String filename;
algorithm
  true := System.regularFileExists(filename);
end existRegularFile;

public function existDirectoryFile
"function: existDirectoryFile
  Checks if a directory exist"
  input String filename;
algorithm
  true := System.directoryExists(filename);
end existDirectoryFile;

protected function loadClassFromMps
"Loads a class or classes from a set of paths in OPENMODELICALIBRARY"
  input String id;
  input list<String> prios;
  input list<String> mps;
  output Absyn.Program outProgram;
protected
  String mp,name;
  Boolean isDir;
algorithm
  (mp,name,isDir) := System.getLoadModelPath(id,prios,mps);
  // print("System.getLoadModelPath: " +& id +& " {" +& stringDelimitList(prios,",") +& "} " +& stringDelimitList(mps,",") +& " => " +& mp +& " " +& name +& " " +& boolString(isDir));
  Config.setLanguageStandardFromMSL(name);
  outProgram := loadClassFromMp(id, mp, name, isDir);
end loadClassFromMps;

protected function loadClassFromMp
  input String id "the actual class name";
  input String path;
  input String name;
  input Boolean isDir;
  output Absyn.Program outProgram;
algorithm
  outProgram := match (id,path,name,isDir)
    local
      String mp,pd,classfile,classfile_1,class_,mp_1,dirfile,packfile,encoding,encodingfile;
      Absyn.Program p;
      Absyn.TimeStamp ts;

    case (_,path,name,false)
      equation
        pd = System.pathDelimiter();
        encodingfile = stringAppendList({path,pd,"package.encoding"});
        encoding = System.trimChar(System.trimChar(Debug.bcallret1(System.regularFileExists(encodingfile),System.readFile,encodingfile,"UTF-8"),"\n")," ");
        p = Parser.parse(path +& pd +& name,encoding);
      then
        p;

    case (id,path,name,true)
      equation
        ts = Absyn.getNewTimeStamp();
        /* Check for path/package.encoding; OpenModelica extension */
        pd = System.pathDelimiter();
        encodingfile = stringAppendList({path,pd,name,pd,"package.encoding"});
        encoding = System.trimChar(System.trimChar(Debug.bcallret1(System.regularFileExists(encodingfile),System.readFile,encodingfile,"UTF-8"),"\n")," ");
        p = loadCompletePackageFromMp(id, name, path, encoding, Absyn.TOP(), Absyn.PROGRAM({},Absyn.TOP(), ts));
      then
        p;
  end match;
end loadClassFromMp;

protected function loadCompletePackageFromMp
"function: loadCompletePackageFromMp
  Loads a whole package from the ModelicaPaths defined in OPENMODELICALIBRARY"
  input String id "actual class identifier";
  input Absyn.Ident inIdent;
  input String inString;
  input String encoding;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (id,inIdent,inString,encoding,inWithin,inProgram)
    local
      String pd,mp_1,packagefile,subdirstr,pack,mp;
      list<Absyn.Class> p1,oldc;
      Absyn.Within w1,within_;
      Absyn.Program p1_1,p2,p;
      list<String> subdirs;
      Absyn.Path wpath_1,wpath;
      Absyn.TimeStamp ts;
    case (id,pack,mp,encoding,(within_ as Absyn.TOP()),Absyn.PROGRAM(classes = oldc))
      equation
        pd = System.pathDelimiter();
        mp_1 = stringAppendList({mp,pd,pack});
        packagefile = stringAppendList({mp_1,pd,"package.mo"});
        existRegularFile(packagefile);
        Absyn.PROGRAM(p1,w1,ts) = Parser.parse(packagefile,encoding);
        Print.printBuf("loading ");
        Print.printBuf(packagefile);
        Print.printBuf("\n");
        p1_1 = Interactive.updateProgram(Absyn.PROGRAM(p1,w1,ts), Absyn.PROGRAM(oldc,Absyn.TOP(),ts));
        subdirs = System.subDirectories(mp_1);
        subdirs = List.sort(subdirs, Util.strcmpBool);
        subdirstr = stringDelimitList(subdirs, ", ");
        p2 = loadCompleteSubdirs(subdirs, id, mp_1, encoding, within_, p1_1);
        p = loadCompleteSubfiles(id, mp_1, encoding, within_, p2);
      then
        p;

    case (id,pack,mp,encoding,(within_ as Absyn.WITHIN(path = wpath)),Absyn.PROGRAM(classes = oldc))
      equation
        pd = System.pathDelimiter();
        mp_1 = stringAppendList({mp,pd,pack});
        packagefile = stringAppendList({mp_1,pd,"package.mo"});
        existRegularFile(packagefile);
        Absyn.PROGRAM(p1,w1,ts) = Parser.parse(packagefile,encoding);
        Print.printBuf("loading ");
        Print.printBuf(packagefile);
        Print.printBuf("\n");
        p1_1 = Interactive.updateProgram(Absyn.PROGRAM(p1,Absyn.WITHIN(wpath),ts),Absyn.PROGRAM(oldc,Absyn.TOP(),ts));
        subdirs = System.subDirectories(mp_1);
        subdirs = List.sort(subdirs, Util.strcmpBool);
        subdirstr = stringDelimitList(subdirs, ", ");
        p2 = loadCompleteSubdirs(subdirs, id, mp_1, encoding, within_, p1_1);
        p = loadCompleteSubfiles(id, mp_1, encoding, within_, p2);
      then
        p;

    case (id,pack,mp,encoding,within_,p) // No package.mo file is different from a parse error
      equation
        pd = System.pathDelimiter();
        mp_1 = stringAppendList({mp,pd,pack});
        packagefile = stringAppendList({mp_1,pd,"package.mo"});
        failure(existRegularFile(packagefile));
      then p;

  end matchcontinue;
end loadCompletePackageFromMp;

protected function loadCompleteSubdirs
"function: loadCompleteSubdirs
  Loads all classes present in a subdirectory"
  input list<String> inStringLst;
  input Absyn.Ident inIdent;
  input String inString;
  input String encoding;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inStringLst,inIdent,inString,encoding,inWithin,inProgram)
    local
      Absyn.Within w,w2,within_;
      list<Absyn.Class> oldcls;
      Absyn.Path pack_1,pack2;
      Absyn.Program p,p_1,oldp;
      String pack,pack1,mp;
      list<String> packs;
      Absyn.TimeStamp ts;

    case ({},_,_,encoding,w,Absyn.PROGRAM(classes = oldcls,within_ = w2, globalBuildTimes=ts))
      then (Absyn.PROGRAM(oldcls,w2,ts));
    case ((pack :: packs),pack1,mp,encoding,(within_ as Absyn.WITHIN(path = pack2)),oldp)
      equation
        pack_1 = Absyn.joinPaths(pack2, Absyn.IDENT(pack1));
        p = loadCompletePackageFromMp(pack, pack, mp, encoding, Absyn.WITHIN(pack_1), oldp);
        p_1 = loadCompleteSubdirs(packs, pack1, mp, encoding, within_, p);
      then
        p_1;

    case ((pack :: packs),pack1,mp,encoding,(within_ as Absyn.TOP()),oldp)
      equation
        pack_1 = Absyn.joinPaths(Absyn.IDENT(pack1), Absyn.IDENT(pack));
        p = loadCompletePackageFromMp(pack, pack, mp, encoding, Absyn.WITHIN(Absyn.IDENT(pack1)), oldp);
        p_1 = loadCompleteSubdirs(packs, pack1, mp, encoding, within_, p);
      then
        p_1;

    /* Do not silently accept broken libraries...
    case ((pack :: packs),pack1,mp,within_,p)
      equation
        p_1 = loadCompleteSubdirs(packs, pack1, mp, within_, p);
      then
        p_1;
    */

    case (pack::_,_,_,_,_,_)
      equation
        Debug.fprintln(Flags.FAILTRACE,"ClassLoader.loadCompleteSubdirs failed: " +& pack);
      then
        fail();
  end matchcontinue;
end loadCompleteSubdirs;

protected function loadCompleteSubfiles
"function: loadCompleteSubfiles
  This function loads all modelicafiles (.mo) from a subdir package."
  input Absyn.Ident inIdent;
  input String inString;
  input String encoding;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inIdent,inString,encoding,inWithin,inProgram)
    local
      list<String> mofiles;
      Absyn.Path within_1,within_;
      Absyn.Program p,oldp;
      String pack,mp;

    case (pack,mp,encoding,Absyn.WITHIN(path = within_),oldp)
      equation
        mofiles = System.moFiles(mp) "Here .mo files in same directory as package.mo should be loaded as sub-packages" ;
        mofiles = List.sort(mofiles, Util.strcmpBool);
        within_1 = Absyn.joinPaths(within_, Absyn.IDENT(pack));
        p = loadSubpackageFiles(mofiles, mp, encoding, Absyn.WITHIN(within_1), oldp);
      then
        p;

    case (pack,mp,encoding,Absyn.TOP(),oldp)
      equation
        mofiles = System.moFiles(mp) "Here .mo files in same directory as package.mo should be loaded as sub-packages" ;
        mofiles = List.sort(mofiles, Util.strcmpBool);
        p = loadSubpackageFiles(mofiles, mp, encoding, Absyn.WITHIN(Absyn.IDENT(pack)), oldp);
      then
        p;

    else
      equation
        Debug.fprintln(Flags.FAILTRACE,"ClassLoader.loadCompleteSubfiles failed");
      then
        fail();
  end matchcontinue;
end loadCompleteSubfiles;

protected function loadSubpackageFiles
"function: loadSubpackageFiles
  Loads all classes from a subpackage"
  input list<String> inStringLst;
  input String inString;
  input String encoding;
  input Absyn.Within inWithin;
  input Absyn.Program inProgram;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inStringLst,inString,encoding,inWithin,inProgram)
    local
      String mp,pd,f_1,f;
      Absyn.Within within_,w;
      list<Absyn.Class> cls,oldc;
      Absyn.Program p_1,p_2;
      list<String> fs;
      Absyn.TimeStamp ts;

    case ({},mp,encoding,within_,Absyn.PROGRAM(classes = cls,within_ = w, globalBuildTimes=ts))
      then Absyn.PROGRAM(cls,w,ts);

    case ((f :: fs),mp,encoding,within_,Absyn.PROGRAM(classes = oldc,globalBuildTimes = ts))
      equation
        pd = System.pathDelimiter();
        f_1 = stringAppendList({mp,pd,f});
        Absyn.PROGRAM(cls,_,_) = Parser.parse(f_1,encoding);
        p_1 = Interactive.updateProgram(Absyn.PROGRAM(cls,within_,ts), Absyn.PROGRAM(oldc,Absyn.TOP(),ts));
        p_2 = loadSubpackageFiles(fs, mp, encoding, within_, p_1);
      then
        p_2;

    else
      equation
        Debug.fprintln(Flags.FAILTRACE,"ClassLoader.loadSubpackageFiles failed");
      then fail();
  end matchcontinue;
end loadSubpackageFiles;

public function loadFile
"function loadFile
  author: x02lucpo
  load the file or the directory structure if the file is named package.mo"
  input String name;
  input String encoding;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (name,encoding)
    local
      String dir,pd,dir_1,name,filename;
      Absyn.Program p1_1,p1;

    case (name,encoding)
      equation
        true = System.regularFileExists(name);
        (dir,"package.mo") = Util.getAbsoluteDirectoryAndFile(name);
        p1_1 = Parser.parse(name,encoding);
        pd = System.pathDelimiter();
        dir_1 = stringAppendList({dir,pd,".."});
        p1 = loadModelFromEachClass(p1_1, dir_1);
      then
        p1;

    case (name,encoding)
      equation
        true = System.regularFileExists(name);
        false = stringEq(name,"package.mo");
        (dir,filename) = Util.getAbsoluteDirectoryAndFile(name);
        p1 = Parser.parse(name,encoding);
      then
        p1;

    // faliling
    else
      equation
        Debug.fprint(Flags.FAILTRACE, "ClassLoader.loadFile failed: "+&name+&"\n");
      then
        fail();
  end matchcontinue;
end loadFile;

protected function loadModelFromEachClass
"function loadModelFromEachClass
  author: x02lucpo
  helper function to loadFile"
  input Absyn.Program inProgram;
  input String inString;
  output Absyn.Program outProgram;
algorithm
  outProgram := matchcontinue (inProgram,inString)
    local
      Absyn.Within a;
      Absyn.Path path;
      Absyn.Program pnew,p_res,p_1;
      String id,dir;
      list<Absyn.Class> res;
      Absyn.TimeStamp ts;

    case (Absyn.PROGRAM(classes = {},within_ = a,globalBuildTimes=ts),_)
      then (Absyn.PROGRAM({},a,ts));

    case (Absyn.PROGRAM(classes = (Absyn.CLASS(name = id) :: res),within_ = a,globalBuildTimes=ts),dir)
      equation
        path = Absyn.IDENT(id);
        pnew = loadClass(path, {"default"}, dir);
        p_res = loadModelFromEachClass(Absyn.PROGRAM(res,a,ts), dir);
        p_1 = Interactive.updateProgram(pnew, p_res);
      then
        p_1;

    case (_,_)
      equation
        Debug.fprint(Flags.FAILTRACE, "ClassLoader.loadModelFromEachClass failed\n");
      then
        fail();
  end matchcontinue;
end loadModelFromEachClass;

end ClassLoader;

