/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/


#include "compiled_function.hpp"
#include <stdio.h>
#include <fstream>
#include <stdlib.h>

#include "function_argument.hpp"
#include "value.hpp"
#include <unistd.h>

//extern "C" {
// #include "../c_runtime/read_write.h"
//}


compiled_function::compiled_function()
{
  
}

compiled_function::compiled_function(std::string filename)
{
  m_filename = filename;
}

compiled_function::~compiled_function()
{

}

bool file_exist(const char* filename)
{
  ifstream file(filename);
  if (file) return true;
  return false;
}

value compiled_function::do_apply(value args)
{
  value ret_val;

  std::string build_command = std::string("sh -c \"")
    + "rm -f success; "
    + "if make -f $MOSHHOME/build/Makefile.single TARGET="+m_filename
    +    " all 1> cmdoutput.tmp 2>&1;"
    + "then echo h > success;"
    + "fi"
    + "\"";

  std::string clean_command = std::string("sh -c \"")
    +   "make -f $MOSHHOME/build/Makefile.single TARGET=" + m_filename 
    +     " clean 1> cmdoutput.tmp 2>&1"
    + "\"";


  if (system(build_command.c_str()) == -1)
    {
      system("cat cmdoutput.tmp");
      system(clean_command.c_str());
      system("rm -f cmdoutput.tmp");
      cout << "Failed to build file" << endl;
      return ret_val;
    }

  if (!file_exist("success"))
    {
      system("cat cmdoutput.tmp");
      system(clean_command.c_str());
      system("rm -f cmdoutput.tmp");
      cout << "Failed to build file" << endl;
      return ret_val;
    }
  else
    {
      system("rm -f success");
      system("rm -f cmdoutput.tmp");
    }

  write_input_file(args,"mosh_in.dat");

  std::string execute_command = "rm -f result.dat;" 
    + m_filename+" mosh_in.dat"+" result.dat";
  
  if (system(execute_command.c_str())==-1)
    {
      cout << "Failed to execute file" << endl;
      system("rm -f result.dat mosh_in.dat");
      return ret_val;
    }
  
  // Read output file
  ret_val = read_result_file("result.dat");

  system("rm -f result.dat mosh_in.dat");
  
  // Return value
  return ret_val;
}

bool compiled_function::match_formal_parameters(value val)
{
  return true;
}

