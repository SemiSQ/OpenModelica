within Modelica.Utilities;
package Files "Functions to work with files and directories"
  function list "List content of file or directory"
    extends Modelica.Icons.Function;
    input String name "If name is a directory, list directory content. If it is a file, list the file content";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    encapsulated package Local "Local utility functions"
      import Modelica.Utilities.*;
      import Modelica.Utilities.Internal;
      function listFile "List content of file"
        input String name;
      protected 
        String file[Streams.countLines(name)]=Streams.readFile(name);
      algorithm 
        for i in 1:min(size(file, 1), 100) loop
          Streams.print(file[i]);
        end for;
      end listFile;

      function sortDirectory "Sort directory in directories and files with alphabetic order"
        input String directory "Directory that was read (including a trailing '/')";
        input String names[:] "File and directory names of a directory in any order";
        output String orderedNames[size(names, 1)] "Names of directories followed by names of files";
        output Integer nDirectories "The first nDirectories entries in orderedNames are directories";
      protected 
        Integer nEntries=size(names, 1);
        Integer nFiles;
        Integer lenDirectory=Strings.length(directory);
        String directory2;
      algorithm 
        directory2:=if Strings.substring(directory, lenDirectory, lenDirectory) == "/" then directory else directory + "/";
        nDirectories:=0;
        nFiles:=0;
        for i in 1:nEntries loop
          if Internal.stat(directory2 + names[i]) == Types.FileType.Directory then 
            nDirectories:=nDirectories + 1;
            orderedNames[nDirectories]:=names[i];
          else
            nFiles:=nFiles + 1;
            orderedNames[nEntries - nFiles + 1]:=names[i];
          end if;
        end for;
        if nDirectories > 0 then 
          orderedNames[1:nDirectories]:=Strings.sort(orderedNames[1:nDirectories], caseSensitive=false);
        end if;
        if nFiles > 0 then 
          orderedNames[nDirectories + 1:nEntries]:=Strings.sort(orderedNames[nDirectories + 1:nEntries], caseSensitive=false);
        end if;
      end sortDirectory;

      function listDirectory "List content of directory"
        input String directoryName;
        input Integer nEntries;
      protected 
        String files[nEntries];
        Integer nDirectories;
      algorithm 
        if nEntries > 0 then 
          Streams.print("\nDirectory \"" + directoryName + "\":");
          files:=Internal.readDirectory(directoryName, nEntries);
          (files,nDirectories):=sortDirectory(directoryName, files);
          if nDirectories > 0 then 
            Streams.print("  Subdirectories:");
            for i in 1:nDirectories loop
              Streams.print("    " + files[i]);
            end for;
            Streams.print(" ");
          end if;
          if nDirectories < nEntries then 
            Streams.print("  Files:");
            for i in nDirectories + 1:nEntries loop
              Streams.print("    " + files[i]);
            end for;
          end if;
        else
          Streams.print("... Directory\"" + directoryName + "\" is empty");
        end if;
      end listDirectory;

    end Local;

    Types.FileType.Type fileType;
  algorithm 
    fileType:=Internal.stat(name);
    if fileType == Types.FileType.RegularFile then 
      Local.listFile(name);
    elseif fileType == Types.FileType.Directory then
      Local.listDirectory(name, Internal.getNumberOfFiles(name));

    elseif fileType == Types.FileType.SpecialFile then
      Streams.error("Cannot list file \"" + name + "\"\n" + "since it is not a regular file (pipe, device, ...)");
    else
      Streams.error("Cannot list file or directory \"" + name + "\"\n" + "since it does not exist");
    end if;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Files.<b>list</b>(name);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
If \"name\" is a regular file, the content of the
file is printed.
</p>
<p>
If \"name\" is a directory, the directory and file names
in the \"name\" directory are printed in sorted order.
</p>
</html>"));
  end list;

  extends Modelica.Icons.Library;
  annotation(version="0.8", versionDate="2004-08-24", preferedView="info", Documentation(info="<HTML>
<p>
This package contains functions to work with files and directories.
As a general convention of this package, '/' is used as directory
separator both for input and output arguments of all functions.
For example:
</p>
<pre>
   exist(\"Modelica/Mechanics/Rotational.mo\");
</pre>
<p>
The functions provide the mapping to the directory separator of the
underlying operating system. Note, that on Windows system the usage
of '\\' as directory separator would be inconvenient, because this
character is also the escape character in Modelica and C Strings.
</p>
<p>
In the table below an example call to every function is given:
</p>
<table border=1 cellspacing=0 cellpadding=2>
  <tr><th><b><i>Function/type</i></b></th><th><b><i>Description</i></b></th></tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Files.list\">list</a>(name)</td>
      <td> List content of file or of directory.</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Files.copy\">copy</a>(oldName, newName)<br>
          <a href=\"Modelica:Modelica.Utilities.Files.copy\">copy</a>(oldName, newName, replace=false)</td>
      <td> Generate a copy of a file or of a directory.</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Files.move\">move</a>(oldName, newName)<br>
          <a href=\"Modelica:Modelica.Utilities.Files.move\">move</a>(oldName, newName, replace=false)</td>
      <td> Move a file or a directory to another place.</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Files.remove\">remove</a>(name)</td>
      <td> Remove file or directory (ignore call, if it does not exist).</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Files.removeFile\">removeFile</a>(name)</td>
      <td> Remove file (ignore call, if it does not exist)</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Files.createDirectory\">createDirectory</a>(name)</td>
      <td> Create directory (if directory already exists, ignore call).</td>
  </tr>
  <tr><td>result = <a href=\"Modelica:Modelica.Utilities.Files.exist\">exist</a>(name)</td>
      <td> Inquire whether file or directory exists.</td>
  </tr>
  <tr><td><a href=\"Modelica:Modelica.Utilities.Files.assertNew\">assertNew</a>(name,message)</td>
      <td> Trigger an assert, if a file or directory exists.</td>
  </tr>
  <tr><td>fullName = <a href=\"Modelica:Modelica.Utilities.Files.fullPathName\">fullPathName</a>(name)</td>
      <td> Get full path name of file or directory name.</td>
  </tr>
  <tr><td>(directory, name, extension) = <a href=\"Modelica:Modelica.Utilities.Files.splitPathName\">splitPathName</a>(name)</td>
      <td> Split path name in directory, file name kernel, file name extension.</td>
  </tr>
  <tr><td>fileName = <a href=\"Modelica:Modelica.Utilities.Files.temporaryFileName\">temporaryFileName</a>()</td>
      <td> Return arbitrary name of a file that does not exist<br>
           and is in a directory where access rights allow to <br>
           write to this file (useful for temporary output of files).</td>
  </tr>
</table>
</HTML>"), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  function copy "Generate a copy of a file or of a directory"
    extends Modelica.Icons.Function;
    input String oldName "Name of file or directory to be copied";
    input String newName "Name of copy of the file or of the directory";
    input Boolean replace=false "= true, if an existing file may be replaced by the required copy";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    encapsulated function copyDirectory "Copy a directory"
      import Modelica.Utilities.*;
      import Modelica.Utilities.Internal;
      input String oldName "Old directory name without trailing '/'; existance is guaranteed";
      input String newName "New diretory name without trailing '/'; directory was already created";
      input Boolean replace "= true, if an existing newName may be replaced";
    protected 
      Integer nNames=Internal.getNumberOfFiles(oldName);
      String oldNames[nNames];
      String oldName_i;
      String newName_i;
    algorithm 
      oldNames:=Internal.readDirectory(oldName, nNames);
      for i in 1:nNames loop
        oldName_i:=oldName + "/" + oldNames[i];
        newName_i:=newName + "/" + oldNames[i];
        Files.copy(oldName_i, newName_i, replace);
      end for;
    end copyDirectory;

    Integer lenOldName=Strings.length(oldName);
    Integer lenNewName=Strings.length(newName);
    String oldName2=if Strings.substring(oldName, lenOldName, lenOldName) == "/" then Strings.substring(oldName, 1, lenOldName - 1) else oldName;
    String newName2=if Strings.substring(newName, lenNewName, lenNewName) == "/" then Strings.substring(newName, 1, lenNewName - 1) else newName;
    Types.FileType.Type oldFileType=Internal.stat(oldName2);
    Types.FileType.Type newFileType;
  algorithm 
    annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Files.<b>copy</b>(oldName, newName);
Files.<b>copy</b>(oldName, newName, replace = true);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Function <b>copy</b>(..) copies a file or a directory
to a new location. Via the optional argument <b>replace</b>
it can be defined whether an already existing file may
be replaced by the required copy.
</p>
<p>
If oldName/newName are directories, then the newName
directory may exist. In such a case the content of oldName
is copied into directory newName. If replace = <b>false</b>
it is required that the existing files
in newName are different from the existing files in 
oldName.
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  copy(\"C:/test1/directory1\", \"C:/test2/directory2\");
     -> the content of directory1 is copied into directory2
        if \"C:/test2/directory2\" does not exist, it is newly
        created. If \"replace=true\", files in directory2
        may be overwritten by their copy
  copy(\"test1.txt\", \"test2.txt\")
     -> make a copy of file \"test1.txt\" with the name \"test2.txt\"
        in the current directory
</pre></blockquote>
</HTML>"));
  end copy;

  function move "Move a file or a directory to another place"
    extends Modelica.Icons.Function;
    input String oldName "Name of file or directory to be moved";
    input String newName "New name of the moved file or directory";
    input Boolean replace=false "= true, if an existing file or directory may be replaced";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  algorithm 
    if Strings.find(oldName, "/") == 0 and Strings.find(newName, "/") == 0 then 
      Internal.rename(oldName, newName);
    else
      Files.copy(oldName, newName, replace);
      Files.remove(oldName);
    end if;
    annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Files.<b>move</b>(oldName, newName);
Files.<b>move</b>(oldName, newName, replace = true);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Function <b>move</b>(..) moves a file or a directory
to a new location. Via the optional argument <b>replace</b>
it can be defined whether an already existing file may
be replaced.
</p>
<p>
If oldName/newName are directories, then the newName
directory may exist. In such a case the content of oldName
is moved into directory newName. If replace = <b>false</b>
it is required that the existing files
in newName are different from the existing files in 
oldName.
</p>
<h3><font color=\"#008000\">Example</font></h3>
<blockquote><pre>
  move(\"C:/test1/directory1\", \"C:/test2/directory2\");
     -> the content of directory1 is moved into directory2.
        Afterwards directory1 is deleted.
        if \"C:/test2/directory2\" does not exist, it is newly
        created. If \"replace=true\", files in directory2
        may be overwritten
   move(\"test1.txt\", \"test2.txt\")
     -> rename file \"test1.txt\" into \"test2.txt\"
        within the current directory
</pre></blockquote>
</HTML>"));
  end move;

  function remove "Remove file or directory (ignore call, if it does not exist)"
    extends Modelica.Icons.Function;
    input String name "Name of file or directory to be removed";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    encapsulated function removeDirectory "Remove a directory, even if it is not empty"
      import Modelica.Utilities.*;
      import Modelica.Utilities.Internal;
      input String name;
    protected 
      Integer nNames=Internal.getNumberOfFiles(name);
      Integer lenName=Strings.length(name);
      String fileNames[nNames];
      String name2=if Strings.substring(name, lenName, lenName) == "/" then Strings.substring(name, lenName - 1, lenName - 1) else name;
    algorithm 
      fileNames:=Internal.readDirectory(name2, nNames);
      for i in 1:nNames loop
        Files.remove(name2 + "/" + fileNames[i]);
      end for;
      Internal.rmdir(name2);
    end removeDirectory;

    String fullName=Files.fullPathName(name);
    Types.FileType.Type fileType=Internal.stat(fullName);
  algorithm 
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Files.<b>remove</b>(name);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Removes the file or directory \"name\". If \"name\" does not exist,
the function call is ignored. If \"name\" is a directory, first
the content of the directory is removed and afterwards
the directory itself.
</p>
<p>
This function is silent, i.e., it does not print a message.
</p>
</html>"));
  end remove;

  function removeFile "Remove file (ignore call, if it does not exist)"
    extends Modelica.Icons.Function;
    input String fileName "Name of file that should be removed";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    Types.FileType.Type fileType=Internal.stat(fileName);
  algorithm 
    if fileType == Types.FileType.RegularFile then 
      Internal.removeFile(fileName);
    elseif fileType == Types.FileType.Directory then
      Streams.error("File \"" + fileName + "\" should be removed.\n" + "This is not possible, because it is a directory");

    elseif fileType == Types.FileType.SpecialFile then
      Streams.error("File \"" + fileName + "\" should be removed.\n" + "This is not possible, because it is a special file (pipe, device, etc.)");
    end if;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Files.<b>removeFile</b>(fileName);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Removes the file \"fileName\". If \"fileName\" does not exist,
the function call is ignored. If \"fileName\" exists but is
no regular file (e.g., directory, pipe, device, etc.) an
error is triggered. 
</p>
<p>
This function is silent, i.e., it does not print a message.
</p>
</html>"));
  end removeFile;

  function createDirectory "Create directory (if directory already exists, ignore call)"
    extends Modelica.Icons.Function;
    input String directoryName "Name of directory to be created (if present, ignore call)";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    encapsulated package Local "Local utility functions"
      import Modelica.Utilities.*;
      import Modelica.Utilities.Internal;
      function existDirectory "Inquire whether directory exists; if present and not a directory, trigger an error"
        input String directoryName;
        output Boolean exists "true if directory exists";
      protected 
        Types.FileType.Type fileType=Internal.stat(directoryName);
      end existDirectory;

      function assertCorrectIndex "Print error, if index to last essential character in directory is wrong"
        input Integer index "Index must be > 0";
        input String directoryName "Directory name for error message";
      algorithm 
        if index < 1 then 
          Streams.error("It is not possible to create the directory\n" + "\"" + directoryName + "\"\n" + "because this directory name is not valid");
        end if;
      end assertCorrectIndex;

    end Local;

    String fullName;
    Integer index;
    Integer oldIndex;
    Integer lastIndex;
    Boolean found;
    Boolean finished;
    Integer nDirectories=0 "Number of directories that need to be generated";
  algorithm 
    if not Local.existDirectory(directoryName) then 
      fullName:=Files.fullPathName(directoryName);
      index:=Strings.length(fullName);
      if Strings.substring(fullName, index, index) == "/" then 
        index:=index - 1;
        Local.assertCorrectIndex(index, fullName);
      end if;
      lastIndex:=index;
      fullName:=Strings.substring(fullName, 1, index);
      found:=false;
      while (not found) loop
        oldIndex:=index;
        index:=Strings.findLast(fullName, "/", startIndex=index);
        if index == 0 then 
          index:=oldIndex;
          found:=true;
        else
          index:=index - 1;
          Local.assertCorrectIndex(index, fullName);
          found:=Local.existDirectory(Strings.substring(fullName, 1, index));
        end if;
      end while;
      index:=oldIndex;
      finished:=false;
      while (not finished) loop
        Internal.mkdir(Strings.substring(fullName, 1, index));
      end while;
    end if;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Files.<b>createDirectory</b>(directoryName);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Creates directory \"directorName\". If this directory already exists,
the function call is ignored. If several directories in \"directoryName\"
do not exist, all of them are created. For example, assume
that directory \"E:/test1\" exists and that directory
\"E:/test1/test2/test3\" shall be created. In this case
the directories \"test2\" in \"test1\" and \"test3\" in \"test2\"
are created.
</p>
<p>
This function is silent, i.e., it does not print a message.
In case of error (e.g., \"directoryName\" is an existing regular
file), an assert is triggered.
</p>
</html>"));
  end createDirectory;

  function exist "Inquire whether file or directory exists"
    extends Modelica.Icons.Function;
    input String name "Name of file or directory";
    output Boolean result "= true, if file or directory exists";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  algorithm 
    result:=Internal.stat(name) > Types.FileType.NoFile;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
result = Files.<b>exist</b>(name);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Returns true, if \"name\" is an existing file or directory.
If this is not the case, the function returns false.
</p>
</html>"));
  end exist;

  function assertNew "Trigger an assert, if a file or directory exists"
    extends Modelica.Icons.Function;
    input String name "Name of file or directory";
    input String message="This is not allowed." "Message that should be printed after the default message in a new line";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    Types.FileType.Type fileType=Internal.stat(name);
  algorithm 
    if fileType == Types.FileType.RegularFile then 
      Streams.error("File \"" + name + "\" already exists.\n" + message);
    elseif fileType == Types.FileType.Directory then
      Streams.error("Directory \"" + name + "\" already exists.\n" + message);

    elseif fileType == Types.FileType.SpecialFile then
      Streams.error("A special file (pipe, device, etc.) \"" + name + "\" already exists.\n" + message);
    end if;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
Files.<b>assertNew</b>(name);
Files.<b>assertNew</b>(name, message=\"This is not allowed\");
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Triggers an assert, if \"name\" is an existing file or
directory. The error message has the following structure:
</p>
<pre>
  File \"&lt;name&gt;\" already exists.
  &lt;message&gt;
</pre>
</p>
</html>"));
  end assertNew;

  function fullPathName "Get full path name of file or directory name"
    extends Modelica.Icons.Function;
    input String name "Absolute or relative file or directory name";
    output String fullName "Full path of 'name'";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));

    external "C" fullName=ModelicaInternal_fullPathName(name) ;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
fullName = Files.<b>fullPathName</b>(name);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Returns the full path name of a file or directory \"name\".
</p>
</html>"));
  end fullPathName;

  function splitPathName "Split path name in directory, file name kernel, file name extension"
    extends Modelica.Icons.Function;
    input String pathName "Absolute or relative file or directory name";
    output String directory "Name of the directory including a trailing '/'";
    output String name "Name of the file without the extension";
    output String extension "Extension of the file name. Starts with '.'";
    annotation(preferedView="info", Documentation(info="<HTML>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
(directory, name, extension) = Files.<b>splitPathName</b>(pathName);
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Function <b>splitPathName</b>(..) splits a path name into its parts.
</p>
<h3><font color=\"#008000\">Example</font></h3>
<pre>
  (directory, name, extension) = Files.splitPathName(\"C:/user/test/input.txt\")
  
  -> directory = \"C:/user/test/\"
     name      = \"input\"
     extension = \".txt\"
</pre>
</HTML>"), Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));
  protected 
    Integer lenPath=Strings.length(pathName);
    Integer i=lenPath;
    Integer indexDot=0;
    Integer indexSlash=0;
    String c;
  algorithm 
    while (i >= 1) loop
      c:=Strings.substring(pathName, i, i);
    end while;
  end splitPathName;

  function temporaryFileName "Return arbitrary name of a file that does not exist and is in a directory where access rights allow to write to this file (useful for temporary output of files)"
    extends Modelica.Icons.Function;
    output String fileName "Full path name of temporary file";
    annotation(Icon(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})), Diagram(coordinateSystem(extent={{-100,100},{100,-100}}, preserveAspectRatio=true, initialScale=0.1, grid={10,10})));

    external "C" fileName=ModelicaInternal_temporaryFileName(0) ;
    annotation(preferedView="info", Documentation(info="<html>
<h3><font color=\"#008000\">Syntax</font></h3>
<blockquote><pre>
fileName = Files.<b>temporaryFileName</b>();
</pre></blockquote>
<h3><font color=\"#008000\">Description</font></h3>
<p>
Return arbitrary name of a file that does not exist
and is in a directory where access rights allow to 
write to this file (useful for temporary output of files).
</p>
</html>"));
  end temporaryFileName;

end Files;
