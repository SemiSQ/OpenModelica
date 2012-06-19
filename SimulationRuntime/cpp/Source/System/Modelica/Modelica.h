#pragma once

#include <string>
//#include <vector>
#include <algorithm>
#include <map>
#include <cmath>
using namespace std;
#define BOOST_UBLAS_SHALLOW_ARRAY_ADAPTOR
#include <boost/assign/std/vector.hpp> // for 'operator+=()'
#include <boost/assign/list_of.hpp> // for 'list_of()'
#include <boost/unordered_map.hpp> 
#include <boost/ref.hpp>
#include <boost/bind.hpp>
#include <boost/function.hpp>
#include <boost/lexical_cast.hpp> 
#include <boost/numeric/conversion/cast.hpp>
#include "boost/tuple/tuple.hpp"
#include <boost/circular_buffer.hpp>
#include <boost/foreach.hpp>
#include "Utils/extension/shared_library.hpp"
#include "Utils/extension/extension.hpp"
#include "Utils/extension/factory.hpp"
#include "Utils/extension/type_map.hpp"
#include "Utils/extension/convenience.hpp"
#include <boost/numeric/ublas/storage.hpp> 
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/io.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_proxy.hpp>

using namespace boost::extensions;
using namespace boost::assign;
using namespace boost::numeric;


using boost::unordered_map;
using boost::lexical_cast;
using boost::numeric_cast;
using boost::tuple;
using boost::tie;
using boost::get;
using boost::make_tuple;

using std::max;
using std::min;
using std::string;
typedef  double modelica_real ;
typedef  int modelica_integer;
typedef  bool modelica_boolean;
typedef  bool  edge_rettype;
typedef  bool sample_rettype;
typedef double cos_rettype;
typedef double cosh_rettype;
typedef double sin_rettype;
typedef double sinh_rettype;
typedef double log_rettype;
typedef double tan_rettype;
typedef double atan_rettype;
typedef double tanh_rettype;
typedef double exp_rettype;
typedef double sqrt_rettype;
typedef double abs_rettype;
typedef double max_rettype;
typedef double min_rettype;
typedef double arctan_rettype;
typedef double floorRetType;
typedef double asinRetType;
typedef double tan_rettype;
typedef double tanhRetType;
typedef double acosRetType;
typedef double logRetType;
typedef double coshRetType;
typedef ublas::shallow_array_adaptor<double> adaptor_t;
typedef ublas::vector<double, adaptor_t> shared_vector_t;
typedef ublas::matrix<double, adaptor_t> shared_matrix_t;
