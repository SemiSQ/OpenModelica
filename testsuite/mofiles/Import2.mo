// name:     Import2
// keywords: import
// status:   incorrect
// 
// Import is not inherited through extends.
// 

package A
  package B
    partial model C
      Real x;
    end C;
    model D
      extends C(x=5);
    end D;
  end B;
  package B1
    model C
      extends B.C(x=4);
    end C;
  end B1;
  package B2
    model C
      extends B.C(x=7);
    end C;
    model E=B.C(x=6);
  end B2;
end A;
   
class Import1
  import A.B.*;
  import A.B2.*;
  import A.B1.C;
  import MyC=A.B2.C;
end Import1;

class Import2 
  extends Import1;
  C c;
  D d;
  E e;
  MyC myc;
end Import2;
// Result:
// Error processing file: Import2.mo
// [Import2.mo:39:3-39:6:writable] Error: Class C not found in scope Import2 while instantiating c.
// 
// # Error encountered! Exiting...
// # Please check the error message and the flags.
// 
// Execution failed!
// endResult
