#ifndef INDEX_SPEC_H_
#define INDEX_SPEC_H_

struct index_spec_s
{
  int ndims;
  int* dim_size;
  int** index;
};

typedef struct index_spec_s index_spec_t;

void alloc_index_spec(index_spec_t* s);

#endif
