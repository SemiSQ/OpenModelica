// name:     VectorizeExtendedType
// keywords: vectorization extends
// status:   correct
// 
// Fixed bug #1119: http://openmodelica.ida.liu.se:8080/cb/issue/1119?navigation=true
// Fixed bug #1138: http://openmodelica.ida.liu.se:8080/cb/issue/1138?navigation=true
// 

type Real2
	extends Real;
end Real2;

type Real3
	extends Real2;
end Real3;

type Axis = Real2[3];

model VectorizeExtendedType
	parameter Real2 r1[3] = {1,2,3};
	Real3 r2[3] = {3,2,1};
	parameter Axis n = {0, -1, 0};
end VectorizeExtendedType;

// fclass VectorizeExtendedType
// parameter Real r1[1] = 1;
// parameter Real r1[2] = 2;
// parameter Real r1[3] = 3;
// Real r2[1] = 3.0;
// Real r2[2] = 2.0;
// Real r2[3] = 1.0;
// parameter Real n[1] = 0;
// parameter Real n[2] = -1;
// parameter Real n[3] = 0;
// end VectorizeExtendedType;
