#include "symboltable.hpp"

#include "builtin_function.hpp"
#include "compiled_function.hpp"


#include <iostream>
#include <fstream>

symboltable::symboltable()
{
  // Initialize builtin functions
  //  cout << "Building symboltable" << endl;
  //  m_builtin_functions.insert(std::make_pair(std::string("abs"),value(new abs_t)));
  //m_builtin_functions.insert(std::make_pair(std::string("sign"),value(new sign_t)));
  // cout << "Finished building symboltable" << endl;

  // m_symboltable[(std::make_pair(std::string("abs"),value(generate_unary_fcn(ptr_fun(abs)))));
  //  m_symboltable["abs"] = value(generate_unary_fcn(ptr_fun(abs)));
  
  // Insert intrinsic mathematical functions
  m_symboltable["abs"] = value(new abs_t);
  m_symboltable["div"] = value(new bt_div_t);
  m_symboltable["mod"] = value(new mod_t);
  m_symboltable["rem"] = value(new rem_t);
  m_symboltable["sqrt"] = value(new sqrt_t);
  m_symboltable["sign"] = value(new sign_t);
  m_symboltable["ceil"] = value(new ceil_t);
  m_symboltable["floor"] = value(new floor_t);
  m_symboltable["integer"] = value(new integer_t);

}

symboltable::~symboltable()
{

}

void symboltable::insert(std::string name, value val)
{
  m_symboltable.insert(std::make_pair(name,val));
}

value* symboltable::lookup(std::string name)
{
  value* res = do_lookup(name);
  return res;
//   if (!res)
//     {
//       return res;
//     }
//   else
//     {
//       return res;
//     }
}

value* symboltable::lookup_function(std::string name)
{
  // Search among builtin functions
  value* res = do_lookup(name);
  
  if (!res)
    {
      // Search on the file system
      res = do_file_lookup(name);
     //  if (!res)
// 	{
// 	  throw run_time_error("Failed to resolve "+name+".");
// 	}
    }
  return res;
}

value* symboltable::do_lookup(std::string name)
{
  std::map<std::string,value>::iterator pos;
  pos = m_symboltable.find(name);
  if (pos != m_symboltable.end())
    {
      return &(pos->second);
    }
  else
    {
      return 0;
    }
}

value* symboltable::do_file_lookup(std::string name)
{
  std::ifstream file;
  std::string filename = name;
  std::string mo_filename = name + ".mo";
  
  file.open(mo_filename.c_str());
  if (!file)
    {
      std::cerr << "Could not open file: " << mo_filename << endl;
      return 0;
    }
  
  file.close();
  
  // Found file
  value new_val = value(new compiled_function(filename));
  insert(name,new_val);
  
  return do_lookup(name);
}
