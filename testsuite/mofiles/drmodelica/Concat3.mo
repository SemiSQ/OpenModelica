// name:     Concat3
// keywords: <insert keywords here>
// status:   correct
// 
// MORE WORK HAS TO BE DONE ON THIS FILE!
// Drmodelica: 7.3 General Array concatenation (p. 213)
// 

class Concat3
	Real[2, 3] r1 = cat(1, {{1.0, 2.0, 3}}, {{4, 5, 6}});
	Real[2, 6] r2 = cat(2, r1, r1);
	Real[2, 3] r3 = cat(2, r1);
	Real[4, 3] r4 = cat(1, r1, r1);
	Real[:] r5 = cat(1, {1,2,3}, {4,time,6});
end Concat3;

// Result:
// class Concat3
//   Real r1[1,1] = 1.0;
//   Real r1[1,2] = 2.0;
//   Real r1[1,3] = 3.0;
//   Real r1[2,1] = 4.0;
//   Real r1[2,2] = 5.0;
//   Real r1[2,3] = 6.0;
//   Real r2[1,1] = r1[1,1];
//   Real r2[1,2] = r1[1,2];
//   Real r2[1,3] = r1[1,3];
//   Real r2[1,4] = r1[1,1];
//   Real r2[1,5] = r1[1,2];
//   Real r2[1,6] = r1[1,3];
//   Real r2[2,1] = r1[2,1];
//   Real r2[2,2] = r1[2,2];
//   Real r2[2,3] = r1[2,3];
//   Real r2[2,4] = r1[2,1];
//   Real r2[2,5] = r1[2,2];
//   Real r2[2,6] = r1[2,3];
//   Real r3[1,1] = r1[1,1];
//   Real r3[1,2] = r1[1,2];
//   Real r3[1,3] = r1[1,3];
//   Real r3[2,1] = r1[2,1];
//   Real r3[2,2] = r1[2,2];
//   Real r3[2,3] = r1[2,3];
//   Real r4[1,1] = r1[1,1];
//   Real r4[1,2] = r1[1,2];
//   Real r4[1,3] = r1[1,3];
//   Real r4[2,1] = r1[2,1];
//   Real r4[2,2] = r1[2,2];
//   Real r4[2,3] = r1[2,3];
//   Real r4[3,1] = r1[1,1];
//   Real r4[3,2] = r1[1,2];
//   Real r4[3,3] = r1[1,3];
//   Real r4[4,1] = r1[2,1];
//   Real r4[4,2] = r1[2,2];
//   Real r4[4,3] = r1[2,3];
//   Real r5[1] = 1.0;
//   Real r5[2] = 2.0;
//   Real r5[3] = 3.0;
//   Real r5[4] = 4.0;
//   Real r5[5] = time;
//   Real r5[6] = 6.0;
// end Concat3;
// endResult
