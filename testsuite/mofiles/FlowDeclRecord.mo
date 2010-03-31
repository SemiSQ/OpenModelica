// name: FlowDeclRecord
// keywords: flow
// status: correct
//
// Tests the flow prefix on a record type
//

record FlowRecord
  Real r;
end FlowRecord;

class FlowDeclRecord
  flow FlowRecord fr;
equation
  fr.r = 1.0;
end FlowDeclRecord;

// Result:
// fclass FlowDeclRecord
// Real fr.r;
// equation
//   fr.r = 1.0;
// end FlowDeclRecord;
// endResult
