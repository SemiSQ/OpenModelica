#include "value.hpp"

#include "modelica_function.hpp"
#include "function_argument.hpp"
#include "runtime/modelica_runtime_error.hpp"
#include "runtime/modelica_array.hpp"
#include "runtime/numerical_array.hpp"

#include <cmath>

value::value() : m_function(0)//,m_function_argument(0)
{
}

value::value(double val)
{
  m_real = val;
  m_basic_type = create_real();
}

value::value(bool val)
{
  m_boolean = val;
  m_basic_type = create_boolean();
}

value::value(int val)
{
  m_integer = val;
  m_basic_type = create_integer();
}

value::value(std::string const& val)
{
  m_string = val;
  m_basic_type = create_string();
}

value::value(const real_array& arr)
{
  m_real_array = arr;
  m_basic_type = create_real_array(arr.size());
}

value::value(const integer_array& arr)
{
  m_integer_array = arr;
  m_basic_type = create_integer_array(arr.size());
}

value::value(const string_array& arr)
{
  m_string_array = arr;
  m_basic_type = create_string_array(arr.size());
}

value::value(const boolean_array& arr)
{
  m_boolean_array = arr;
  m_basic_type = create_boolean_array(arr.size());
}

value::value(const tuple_type& tuple)
{
  m_tuple = tuple;
  m_basic_type = create_tuple();
}

value::value(modelica_function* fcn)
{
  m_function = fcn;
  m_basic_type = create_function_type();
}

// value::value(function_argument* func_arg)
// {
//   m_function_args = func_arg;
//   m_type = fcn_arg;
// }

value::~value()
{
}

value::value(const value& val)
{
  m_basic_type = val.m_basic_type;
  
  if (m_basic_type.is_real())
    {
      m_real = val.m_real;
      m_basic_type = create_real();
      return;
    }
  else if (m_basic_type.is_integer())
    {
      m_integer = val.m_integer;
      m_basic_type = create_integer();
      return;
    }
  else if (m_basic_type.is_string())
    {
      m_string = val.m_string;
      m_basic_type = create_string();
      return;
    }
  else if (m_basic_type.is_boolean())
    {
      m_boolean = val.m_boolean;
      m_basic_type = create_boolean();
      return;
    }
  else if (m_basic_type.is_real_array())
    {
      m_real_array = val.m_real_array;
      m_basic_type = create_real_array(val.m_real_array.size());
      return;
    }
  else if (m_basic_type.is_integer_array())
    {
      m_integer_array = val.m_integer_array;
      m_basic_type = create_integer_array(val.m_integer_array.size());
      return;
    }
  else if (m_basic_type.is_string_array())
    {
      m_string_array = val.m_string_array;
      m_basic_type = create_string_array(val.m_string_array.size());
      return;
    }
  else if (m_basic_type.is_boolean_array())
    {
      m_boolean_array = val.m_boolean_array;
      m_basic_type = create_boolean_array(val.m_boolean_array.size());
      return;
    }
  else if (m_basic_type.is_tuple())
    {
      m_tuple = val.m_tuple;
      m_basic_type = create_tuple();
    }
  else if (m_basic_type.is_function())
    {
      m_function = val.m_function;
      m_basic_type = create_function_type();
      return;
    }
  else if (m_basic_type.is_function_argument())
    {
      m_function_argument = val.m_function_argument;
      m_basic_type = create_function_argument_type();
      return;
    }
}

void value::set_value(std::string val)
{
  m_string = val;
   m_basic_type = create_string();
}

void value::set_value(int val)
{
  m_integer = val;
   m_basic_type = create_integer();
}

void value::set_value(double val)
{
  m_real = val;
  m_basic_type = create_real();
}

void value::set_value(bool val)
{
  m_boolean = val;
  m_basic_type = create_boolean();
}

void value::set_value(modelica_function* fcn)
{
  m_function = fcn;
  m_basic_type = create_function_type();
}

void value::set_value(const real_array& arr)
{
  m_real_array = arr;
  m_basic_type = create_real_array(arr.size());
}

void value::set_value(const string_array& arr)
{
  m_string_array = arr;
  m_basic_type = create_string_array(arr.size());
}

void value::set_value(const boolean_array& arr)
{
  m_boolean_array = arr;
  m_basic_type = create_boolean_array(arr.size());
}

void value::set_value(const integer_array& arr)
{
  m_integer_array = arr;
  m_basic_type = create_integer_array(arr.size());
}

void value::set_value(function_argument* func_arg)
{
  m_function_argument = func_arg;
  m_basic_type = create_function_argument_type();
}

void value::set_value(tuple_type const& tuple)
{
  m_tuple = tuple;
  m_basic_type = create_tuple();
}

void value::make_array(std::vector<value> const& exp_list)
{
  std::vector<double> tmp_real;
  std::vector<int> tmp_integer;
 
  bool is_real = true;
  bool is_integer = true;
  bool is_bool = true;
  bool is_string = true;

  for (unsigned int i = 0; i < exp_list.size(); ++i)
    {
      is_real    = is_real && (exp_list[i].is_real() 
			       || exp_list[i].is_integer());
      is_integer = is_integer && exp_list[i].is_integer();
      is_bool    = is_bool && exp_list[i].is_boolean();
      is_string  = is_string && exp_list[i].is_string();
    }

  if (is_integer)
    {
      std::vector<int> dims(1,exp_list.size());
      integer_array arr(dims);
      std::vector<int> idx(1);
      for (idx[0] = 0; idx[0] < (int)exp_list.size(); ++idx[0])
	{
	  arr.set_element(idx,exp_list[idx[0]].get_integer());
	}
      set_value(arr);
    }
  else if (is_real)
    {
      std::vector<int> dims(1,exp_list.size());
      real_array arr(dims);
      std::vector<int> idx(1);
      for (idx[0] = 0; idx[0] < (int)exp_list.size(); ++idx[0])
	{
	  if (exp_list[idx[0]].is_integer())
	    {
	      arr.set_element(idx,exp_list[idx[0]].get_integer());
	    }
	  else
	    {
	      arr.set_element(idx,exp_list[idx[0]].get_real());
	    }
	}
      set_value(arr);
    }
  else if (is_bool)
    {
      throw modelica_runtime_error("array of booleans not implemented yet");
    }
  else if (is_string)
    {
      throw modelica_runtime_error("array of strings not implemented yet");
    }
  else
    {
      bool is_real_array = true;
      bool is_integer_array = true;
      bool is_bool_array = true;
      bool is_string_array = true;
      bool dims_match = true;
      bool first = true;
      std::vector<int> fdims;
      std::vector<int> dims;

      for (int i = 0; i < (int)exp_list.size(); ++i)
	{
	  if (first)
	    {
	      first = false;
	      if (exp_list[i].is_real_array())
		{
		  fdims = exp_list[i].get_real_array().size();
		}
	      else if (exp_list[i].is_integer_array())
		{
		  fdims = exp_list[i].get_integer_array().size();
		}
	      else if (exp_list[i].is_boolean_array())
		{
		  fdims = exp_list[i].get_boolean_array().size();
		}
	      else if (exp_list[i].is_string_array())
		{
		  fdims = exp_list[i].get_string_array().size();
		}
	    }
	  else
	    {
	      if (exp_list[i].is_real_array())
		{
		  dims = exp_list[i].get_real_array().size();
		}
	      else if (exp_list[i].is_integer_array())
		{
		  dims = exp_list[i].get_integer_array().size();
		}
	      else if (exp_list[i].is_boolean_array())
		{
		  dims = exp_list[i].get_boolean_array().size();
		}
	      else if (exp_list[i].is_string_array())
		{
		  dims = exp_list[i].get_string_array().size();
		}
	      dims_match = dims_match && (dims == fdims);
	    }

	  is_real_array=is_real_array && (exp_list[i].is_real_array() 
					  || exp_list[i].is_integer_array());
	  is_integer_array =is_integer_array && exp_list[i].is_integer_array();
	  is_bool_array    = is_bool_array && exp_list[i].is_boolean_array();
	  is_string_array  = is_string_array && exp_list[i].is_string_array();
	}

      if (is_integer_array)
	{
	  dims.insert(dims.begin(),(int)exp_list.size());
	  std::vector<modelica_array<int> > arrs(exp_list.size(),integer_array());
	  
	  for (int i = 0; i < (int)exp_list.size(); ++i)
	    {
	      arrs[i] = exp_list[i].get_integer_array();
	    }
	  integer_array arr = create_array2(arrs);
	  set_value(arr);
	}
      else if (is_real_array)
	{
	  dims.insert(dims.begin(),(int)exp_list.size());
	  std::vector<modelica_array<double> > arrs(exp_list.size(),real_array());
	  
	  for (int i = 0; i < (int)exp_list.size(); ++i)
	    {
	      if (exp_list[i].is_integer_array())
		{
		  arrs[i] = real_array(exp_list[i].get_integer_array());
		}
	      else
		{
		  arrs[i] = exp_list[i].get_real_array();
		}
	    }
	  real_array arr = create_array2(arrs);
	  set_value(arr);
	}
      else if (is_bool_array)
	{
	  throw modelica_runtime_error("array of booleans not implemented yet");
	}
      else if (is_string_array)
	{
	  throw modelica_runtime_error("array of strings not implemented yet");
	}
      else
	{
	  throw modelica_runtime_error("mismatched types");
	}
    }

}
	      
std::string value::get_string() const
{
  return m_string;
}


double value::get_real() const
{
  return m_real;
}


int value::get_integer() const
{
  return m_integer;
}


bool value::get_boolean() const
{
  return m_boolean;
}

modelica_function* value::get_function()
{
  return m_function;
}

real_array    const& value::get_real_array()    const {return m_real_array;}
integer_array const& value::get_integer_array() const {return m_integer_array;}
string_array  const& value::get_string_array()  const {return m_string_array;}
boolean_array const& value::get_boolean_array() const {return m_boolean_array;}
value::tuple_type const& value::get_tuple()     const {return m_tuple;}

real_array&    value::get_real_array()    { return m_real_array; }
integer_array& value::get_integer_array() { return m_integer_array; }
string_array&  value::get_string_array()  { return m_string_array; }
boolean_array& value::get_boolean_array() { return m_boolean_array; }
value::tuple_type& value::get_tuple()     { return m_tuple; }

function_argument* value::get_function_argument()
{
  return m_function_argument;
}


modelica_type value::type() const
{
  return m_basic_type;
}

void value::set_type(const modelica_type& t)
{
  m_basic_type = t;
}

// value::type_en value::type() const
// {
//   return m_type;
// }

// void value::set_type(value::type_en type)
// {
//   m_type = type;
// }

bool value::is_numeric() const
{
  return m_basic_type.is_numeric();
}

bool value::is_real() const
{
  return m_basic_type.is_real();
}

bool value::is_integer() const
{
  return m_basic_type.is_integer();
}

bool value::is_boolean() const
{
  return m_basic_type.is_boolean();
}

bool value::is_string() const
{
  return m_basic_type.is_string();
}

bool value::is_function() const
{
  return m_basic_type.is_function();
}

bool value::is_array() const
{
  return m_basic_type.is_array();
  //return m_type == array;
  // return (m_type == str_array) || (m_type == integer_array_t) 
//     || (m_type == real_array_t) || (m_type == boolean_array);
}

bool value::is_real_array() const
{
  return m_basic_type.is_real_array();
}

bool value::is_integer_array() const
{
  return m_basic_type.is_integer_array();
}

bool value::is_string_array() const
{
  return m_basic_type.is_string_array();
}

bool value::is_boolean_array() const
{
  return m_basic_type.is_boolean_array();
}

bool value::is_tuple() const
{
  return m_basic_type.is_tuple();
}

bool value::is_function_argument() const
{
  //  return m_is_function_argument;
  return m_basic_type.is_function_argument();
}

// void value::append_to_array(const value& val)
// {
//   m_array.push_back(val);
// }

// void value::append_to_function_arguments(const value& val)
// {
//   //   m_function_arguments.push_back(val);
// }

// value::array_iterator value::array_begin()
// {
//   return m_array.begin();
// }

// value::array_iterator value::array_end()
// {
//   return m_array.end();
// }

// int value::array_size()
// {
//   return m_array.size();
// }

// int value::function_arguments_size()
// {
  
// }

ostream& operator<< (ostream& o, const value& v)
{
  
  if (v.is_integer()) 
    {
      o << "Integer:\n";
      o << v.m_integer;
    }

  if (v.is_boolean())
    {
      o << "Boolean:\n";
      o << v.m_boolean;
    }
  
  if (v.is_real())
    {
      o << "Real:\n";
      o << v.m_real;
    }

  if (v.is_string())
    {
      o << "String:\n";
      o << " \"" << v.m_string << "\"";
    }

  if (v.is_function())
    {
      o << "Function:\n";
      o << v.m_function->name() << "()";
    }

  if (v.is_real_array())
    {
      real_array const& arr = v.get_real_array();
      o << "Real[";
      for (int i = 0; i < arr.ndims(); ++i)
	{
	  if (i > 0) o << ", ";
	  o << arr.size(i);
	  
	}
      o << "]:\n";
      o << arr;
    }

  if (v.is_integer_array())
    {
      integer_array const& arr = v.get_integer_array();
      o << "Integer[";
      for (int i = 0; i < arr.ndims(); ++i)
	{
	  if (i > 0) o << ", ";
	  o << arr.size(i);
	  
	}
      o << "]:\n";
      o << arr;
    }
  
  if (v.is_string_array())
    {
      o << v.get_string_array();
    }

  if (v.is_boolean_array())
    {
      o << v.get_boolean_array();
    }
  if (v.is_tuple())
    {
      value::tuple_type const& tuple = v.get_tuple();
      o << "Tuple: " << tuple.size() << "\n";
      for (value::tuple_type::const_iterator it = tuple.begin();
	   it != tuple.end();
	   ++it)
	{
	  o << *it << "\n";
	}
    }

  return o;
}

const value& value::operator+= (const value& val)
{
  if (!is_numeric() || !val.is_numeric())
    {
      throw modelica_runtime_error("Adding non-numerical value\n");
    }
  if (check_type(*this,val))
    {
      if (is_real_array())
	{
	  m_real_array += val.m_real_array;
	}
      else if (is_integer_array())
	{
	  m_integer_array += val.m_integer_array;
	}
      else if (is_real())
	{
	  m_real += val.m_real;
	}
      else if (is_integer())
	{
	  m_integer += val.m_integer;
	}
      else
	{
	  throw modelica_runtime_error("Internal error in value +=");
	}
    }
  else
    {
      throw modelica_runtime_error("Types do not match\n");
    }
    
  return *this;
}

value value::operator+(const value& v) const
{
  value tmp(*this);

  tmp += v;
  return tmp;
}

const value& value::operator-= (const value& val)
{

    if (!is_numeric() || !val.is_numeric())
    {
      throw modelica_runtime_error("Adding non-numerical value\n");
    }

  if (check_type(*this,val))
    {
      if (is_real_array())
	{
	  m_real_array -= val.m_real_array;
	}
      else if (is_integer_array())
	{
	  m_integer_array -= val.m_integer_array;
	}
      else if (is_real())
	{
	  m_real -= val.m_real;
	}
      else if (is_integer())
	{
	  m_integer -= val.m_integer;
	}
      else
	{
	  throw modelica_runtime_error("Internal error in value +=");
	}
    }
  else
    {
      throw modelica_runtime_error("Types do not match\n");
    }

//   if (val.is_array() || is_array())
//     {
//       m_real_array -= val.m_real_array;
//       m_type = real_array_t;
//     }
//   else if (!is_numeric() || !val.is_numeric())
//     {
//       throw modelica_runtime_error("Subtracting non-numerical value\n");
//     }
  
//   if (val.is_real() || is_real())
//     {
//       m_real = to_double()-val.to_double();
//       m_type = real;
//     }
//   else 
//     {
//       m_integer -= val.m_integer;
//       m_type = integer;
//     }
  
  return *this;
}

value value::operator-(const value& v) const
{
  value tmp(*this);
  tmp -= v;
  return tmp;
}

const value& value::operator*= (const value& val)
{
 //    if (!is_numeric() || !val.is_numeric())
//     {
//       throw modelica_runtime_error("Multiplying non-numerical value\n");
//     }

//   if (val.is_real() || is_real())
//   {
//     m_real = to_double()*val.to_double();
//     m_type = real;
//   }
//   else 
//     {
//       m_integer *= val.m_integer;
//       m_type = integer;
//     }

  return *this;
}

value value::operator*(const value& v) const
{
  value tmp(*this);
  tmp *= v;
  return tmp;
}

const value& value::operator/= (const value& val)
{
//     if (!is_numeric() || !val.is_numeric())
//     {
//       throw modelica_runtime_error("Multiplying non-numerical value\n");
//     }

//   if (val.is_real() || is_real())
//   {
//     m_real = to_double()/val.to_double();
//     m_type = real;
//   }
//   else 
//     {
//       m_real = m_integer / static_cast<double>(val.m_integer);
//       m_type = real;
//     }

  return *this;
}

value value::operator/(const value& v) const
{
  value tmp(*this);
  tmp /= v;
  return tmp;
}

double value::to_double() const
{
  if (!is_numeric())
    {
      throw modelica_runtime_error("to_double on non-numerical value\n");
    }

  if (is_integer()) 
    {
      return static_cast<double>(m_integer);
    }
  else
    {
      return m_real;
    }
}

value value::operator-() const
{
     if (!is_numeric())
	{
	    throw modelica_runtime_error("unary minus on non-numerical value\n");
	}

     value tmp(*this);

     if (is_real_array())
       {
	 tmp.m_real_array = - m_real_array;
	}
      else if (is_integer_array())
	{
	  tmp.m_integer_array = - m_integer_array;
	}
      else if (is_real())
	{
	  tmp.m_real = - m_real;
	}
      else if (is_integer())
	{
	  tmp.m_integer = - m_integer;
	}
     else
       {
	 throw modelica_runtime_error("Internal error in value +=");
       }
        
     return tmp; 
//     if (is_integer()) 
// 	{
// 	    tmp.m_integer = - m_integer;
// 	}
//     else
// 	{
// 	    tmp.m_real = - m_real;
// 	}

    return tmp;
}

const value power(const value& x,const value& y)
{
  if (!x.is_numeric() || !y.is_numeric())
    {
      throw modelica_runtime_error("Power non-numerical value\n");
    }
  
  return value(pow(x.to_double(),y.to_double()));
}

const value not_bool(const value& x)
{
  if (!x.is_boolean())
    {
      throw modelica_runtime_error("Not of a non-boolean value\n");
    }
  
  return value(!(x.m_boolean));
}

const value and_bool(const value& x,const value& y)
{
  
  if (!x.is_boolean())
    {
      throw modelica_runtime_error("And of a non-boolean value\n");
    }
  
  return value(x.m_boolean && y.m_boolean);
}

const value or_bool(const value& x,const value& y)
{
  if (!x.is_boolean())
    {
      throw modelica_runtime_error("Or of a non-boolean value\n");
    }
  
  return value(x.m_boolean || y.m_boolean);
}

const value modelica_if(const value& x, const value& y, const value& z)
{
  if (!x.is_boolean())
    {
      throw modelica_runtime_error("If of a non-boolean value\n");
    }
  
  if (x.get_boolean())
    return y;
  else
    return z;
}

/*const value less(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() < y.to_double());
}*/

const value lesseq(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    bool result = x.to_double() <= y.to_double();
    return value(result);
//    return value(static_cast<bool>(x.to_double() <= y.to_double()));
}

/*const value greater(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() > y.to_double());
}*/

const value greatereq(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() >= y.to_double());
}

const value eqeq(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() == y.to_double());
}

const value lessgt(const value& x, const value& y)
{
    if (!x.is_numeric() || !y.is_numeric())
	{
	    throw modelica_runtime_error("less of a non-numerical value\n");
	}
    
    return value(x.to_double() != y.to_double());
}

const value create_array(const value& x)
{
  value tmp;
  // tmp.set_type(value::real_array_t);
  
  //  tmp.append_to_array(x);
  
  return tmp;
}

const value create_range_array(const value& x, const value& y, const value& z)
{
  if (!x.is_numeric() || !y.is_numeric() || !z.is_numeric())
	{
	    throw modelica_runtime_error("Non-numeric value in range expression\n");
	}
  
  value tmp;
  //tmp.set_type(value::real_array_t);
  

  if (x.is_integer() && y.is_integer() && z.is_integer())
    {
      int size = (z.get_integer()-x.get_integer())/y.get_integer() + 1;
      if (size < 0) size = 0;
      integer_array arr(std::vector<int>(1,size));
      int v = x.get_integer();
      for (integer_array::data_iterator it = arr.data_begin();
	   it != arr.data_end(); ++it)
	{
	  *it = v;
	  v += y.get_integer();
	}
      tmp.set_value(arr);
    }
  else
    {


      double lower = x.is_real() ? x.get_real() : x.get_integer();
      double increment = y.is_real() ? y.get_real() : y.get_integer();
      double upper = z.is_real() ? z.get_real() : z.get_integer();

      int size = (int)floor( (upper-lower)/increment) + 1;
      if (size < 0) size = 0;

      real_array arr(std::vector<int>(1,size));
 
      double v = lower;
      for (real_array::data_iterator it = arr.data_begin();
	   it != arr.data_end(); ++it)
	{
	  *it = v;
	  v += increment;
	}
      tmp.set_value(arr);
    }
  return tmp;
    
}

// const value create_array(const value& x, const value& y)
// {
//   return create_array(x, value(1), y);
// }

bool check_type(value v1,value v2)
{
  if (v1.type().type_equal(v2.type()))
    {
      return true;
    }
  else
    {
      return false;
    }
}
