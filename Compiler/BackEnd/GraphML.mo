/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Link�ping University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�ping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package GraphML
" file:         GraphML
  package:     GraphML
  description: GraphML contains functions to generate a gaphML file for yED 

  
  RCS: $Id: GraphML 9566 2011-08-01 07:04:56Z perost $
"

protected import Util;
protected import List;

/*************************************************
 * types 
 ************************************************/

public constant String COLOR_BLACK      = "000000";
public constant String COLOR_BLUE      = "0000FF";
public constant String COLOR_GREEN      = "339966";
public constant String COLOR_RED      = "FF0000";
public constant String COLOR_DARKRED  = "800000";
public constant String COLOR_WHITE      = "FFFFFF";
public constant String COLOR_YELLOW      = "FFCC00";
public constant String COLOR_GRAY      = "C0C0C0";
public constant String COLOR_PURPLE   = "993366";


public uniontype ShapeType
  record RECTANGLE end RECTANGLE;
  record ROUNDRECTANGLE end ROUNDRECTANGLE;
  record ELLIPSE end ELLIPSE;
  record PARALLELOGRAM end PARALLELOGRAM;
  record HEXAGON end HEXAGON;
  record TRIANGLE end TRIANGLE;
  record OCTAGON end OCTAGON;
  record DIAMOND end DIAMOND;
  record TRAPEZOID end TRAPEZOID;
  record TRAPEZOID2 end TRAPEZOID2;
end ShapeType;

public uniontype LineType
  record LINE end LINE;
  record DASHED end DASHED;
  record DASHEDDOTTED end DASHEDDOTTED;
end LineType;

public uniontype ArrowType
  record ARROWSTANDART end ARROWSTANDART;
end ArrowType;

public uniontype Node
  record NODE
    String id;
    String text;
    String color;
    ShapeType shapeType;
  end NODE;
end Node;

public uniontype EdgeLabel
  record EDGELABEL
    String text;
    String color;
  end EDGELABEL;  
end EdgeLabel;

public uniontype Edge
  record EDGE
    String id;
    String target;
    String source;
    String color;
    LineType lineType;
    Option<EdgeLabel> label;
    tuple<Option<ArrowType>,Option<ArrowType>> arrows;
  end EDGE;
end Edge;

public uniontype Graph
  record GRAPH
    String id;
    Boolean directed;
    list<Node> nodes;
    list<Edge> edges;
  end GRAPH;
end Graph;

/*************************************************
 * public 
 ************************************************/

public function getGraph
"function getGraph
 autor: Frenkel TUD 2011-08
 get a empty graph"
  input String id;
  input Boolean directed;
  output Graph g;
algorithm
  g := GRAPH(id,directed,{},{});
end getGraph;

public function addNode
"function addNode
 autor: Frenkel TUD 2011-08
 add a node"
  input String id;
  input String text;
  input String color;
  input ShapeType shapeType;
  input Graph inG;
  output Graph outG;
protected
  String gid;
  Boolean d;
  list<Node> n;
  list<Edge> e;  
algorithm
  GRAPH(gid,d,n,e) := inG;
  outG := GRAPH(gid,d,NODE(id,text,color,shapeType)::n,e);
end addNode;

public function addEgde
"function addEgde
 autor: Frenkel TUD 2011-08
 add a edge"
  input String id;
  input String target;
  input String source;
  input String color;
  input LineType lineType;
  input Option<EdgeLabel> label;
  input tuple<Option<ArrowType>,Option<ArrowType>> arrows;
  input Graph inG;
  output Graph outG;
protected
  String gid;
  Boolean d;
  list<Node> n;
  list<Edge> e;  
algorithm
  GRAPH(gid,d,n,e) := inG;
  outG := GRAPH(gid,d,n,EDGE(id,target,source,color,lineType,label,arrows)::e);
end addEgde;

public function dumpGraph
"function dumpGraph
 autor: Frenkel TUD 2011-08
 print the graph"
  input Graph inGraph;
  input String name;
algorithm
  dumpStart();
  dumpGraph_Internal(inGraph,"  ");
  dumpEnd();
end dumpGraph;

/*************************************************
 * protected 
 ************************************************/

protected function dumpStart
algorithm
  print("<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n");
  print("<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:y=\"http://www.yworks.com/xml/graphml\" xmlns:yed=\"http://www.yworks.com/xml/yed/3\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://www.yworks.com/xml/schema/graphml/1.1/ygraphml.xsd\">\n");
  print("  <!--Created by yFiles for Java 2.8-->\n");
  print("  <key for=\"graphml\" id=\"d0\" yfiles.type=\"resources\"/>\n");
  print("  <key for=\"port\" id=\"d1\" yfiles.type=\"portgraphics\"/>\n");
  print("  <key for=\"port\" id=\"d2\" yfiles.type=\"portgeometry\"/>\n");
  print("  <key for=\"port\" id=\"d3\" yfiles.type=\"portuserdata\"/>\n");
  print("  <key attr.name=\"url\" attr.type=\"string\" for=\"node\" id=\"d4\"/>\n");
  print("  <key attr.name=\"description\" attr.type=\"string\" for=\"node\" id=\"d5\"/>\n");
  print("  <key for=\"node\" id=\"d6\" yfiles.type=\"nodegraphics\"/>\n");
  print("  <key attr.name=\"Beschreibung\" attr.type=\"string\" for=\"graph\" id=\"d7\"/>\n");
  print("  <key attr.name=\"url\" attr.type=\"string\" for=\"edge\" id=\"d8\"/>\n");
  print("  <key attr.name=\"description\" attr.type=\"string\" for=\"edge\" id=\"d9\"/>\n");
  print("  <key for=\"edge\" id=\"d10\" yfiles.type=\"edgegraphics\"/>\n");
end dumpStart; 

protected function dumpEnd
algorithm
  print("  <data key=\"d0\">\n");
  print("    <y:Resources/>\n");
  print("  </data>\n");
  print("</graphml>\n");
end dumpEnd; 

protected function appendString
  input String inString;
  output String outString;
algorithm
  outString := stringAppend(inString,"  ");
end appendString;

protected function dumpGraph_Internal
  input Graph inGraph;
  input String inString;
algorithm
  _ := match (inGraph,inString)
    local
      String id,sd,t;
      Boolean directed;
      list<Node> nodes;
      list<Edge> edges;
     case(GRAPH(id=id,directed=directed,nodes=nodes,edges=edges),inString)
       equation
         sd = Util.if_(directed,"directed","undirected");
         t = appendString(inString);
         print(inString +& "<graph edgedefault=\"" +& sd +& "\" id=\"" +& id +& "\">\n");
         List.map1_0(nodes,dumpNode,t);
         List.map1_0(edges,dumpEdge,t);
         print(t +& "<data key=\"d7\"/>\n");         
         print(inString +& "</graph>\n");
       then
        ();     
   end match;
end dumpGraph_Internal;  

protected function dumpNode
  input Node inNode;
  input String inString;
algorithm
  _ := match (inNode,inString)
  local 
    String id,t,text,st_str,color;
    ShapeType st;
     case(NODE(id=id,text=text,color=color,shapeType=st) ,inString)
       equation
        print(inString +& "<node id=\"" +& id +& "\">\n");
        t = appendString(inString);
        print(t +& "<data key=\"d5\"/>\n");
        print(t +& "<data key=\"d6\">\n");
        print("        <y:ShapeNode>\n");
        print("          <y:Geometry height=\"30.0\" width=\"30.0\" x=\"17.0\" y=\"60.0\"/>\n");
        print("          <y:Fill color=\"#" +& color +& "\" transparent=\"false\"/>\n");
        print("          <y:BorderStyle color=\"#000000\" type=\"line\" width=\"1.0\"/>\n");
        print("          <y:NodeLabel alignment=\"center\" autoSizePolicy=\"content\" fontFamily=\"Dialog\" fontSize=\"12\" fontStyle=\"plain\" hasBackgroundColor=\"false\" hasLineColor=\"false\" height=\"18.701171875\" modelName=\"internal\" modelPosition=\"c\" textColor=\"#000000\" visible=\"true\" width=\"228.806640625\" x=\"1\" y=\"1\">" +& text +&"</y:NodeLabel>\n");
        st_str = getShapeTypeString(st);
        print("          <y:Shape type=\"" +& st_str +& "\"/>\n");
        print("        </y:ShapeNode>\n");
        print(t +& "</data>\n");
        print(inString +& "</node>\n");
       then
        ();     
   end match;
end dumpNode;  

protected function getShapeTypeString
  input ShapeType st;
  output String str;
algorithm
  str := match (st)
    case RECTANGLE() then "rectangle";
    case ROUNDRECTANGLE() then "roundrectangle";
    case ELLIPSE() then "ellipse";
    case PARALLELOGRAM() then "parallelogram";
    case HEXAGON() then "hexagon";
    case TRIANGLE() then "triangle";
    case OCTAGON() then "octagon";
    case DIAMOND() then "diamond";
    case TRAPEZOID() then "trapezoid";
    case TRAPEZOID2() then "trapezoid2";
   end match;
end getShapeTypeString;

protected function dumpEdge
  input Edge inEdge;
  input String inString;
algorithm
  _ := match (inEdge,inString)
  local 
    String id,t,target,source,color,lt_str,sa_str,ta_str,sl_str;  
    LineType lt;
    Option<ArrowType> sarrow,tarrow;
    Option<EdgeLabel> label;
   case(EDGE(id=id,target=target,source=source,color=color,lineType=lt,label=label,arrows=(sarrow,tarrow)),inString)
     equation
      print(inString +& "<edge id=\"" +& id +& "\" source=\"" +& source +& "\" target=\"" +& target +& "\">\n");
      t = appendString(inString);
      print(t +& "<data key=\"d8\"/>\n");
      print(t +& "<data key=\"d9\"><![CDATA[UMLuses]]></data>\n");
      print(t +& "<data key=\"d10\">\n");
      print("        <y:PolyLineEdge>\n");
      print("          <y:Path sx=\"0.0\" sy=\"0.0\" tx=\"0.0\" ty=\"0.0\"/>\n");
      lt_str = getLineTypeString(lt);
      print("          <y:LineStyle color=\"#" +& color +& "\" type=\"" +& lt_str +& "\" width=\"2.0\"/>\n");
      sl_str = getEdgeLabelString(label);
      print(sl_str);      
      sa_str = getArrowTypeString(sarrow);
      ta_str = getArrowTypeString(tarrow);
      print("          <y:Arrows source=\"" +& sa_str +& "\" target=\"" +& ta_str +& "\"/>\n");
      print("          <y:BendStyle smoothed=\"false\"/>\n");
      print("        </y:PolyLineEdge>\n");
      print(t +& "</data>\n");
      print(inString +& "</edge>\n");      
     then
      ();   
   end match;
end dumpEdge; 

protected function getEdgeLabelString
  input Option<EdgeLabel> label;
  output String outStr;
algorithm
  outStr := match(label)
    local
      String text,color;
    case (NONE()) then "";
    case (SOME(EDGELABEL(text=text,color=color)))
      then
        stringAppendList({"          <y:EdgeLabel alignment=\"center\" distance=\"2.0\" fontFamily=\"Dialog\" fontSize=\"20\" fontStyle=\"plain\" hasBackgroundColor=\"false\" hasLineColor=\"false\" height=\"28.501953125\" modelName=\"six_pos\" modelPosition=\"tail\" preferredPlacement=\"anywhere\" ratio=\"0.5\" textColor=\"",color,"\" visible=\"true\" width=\"15.123046875\" x=\"47.36937571050203\" y=\"17.675232529529524\">",text,"</y:EdgeLabel>\n"});
  end match;
end getEdgeLabelString;

protected function getArrowTypeString
  input Option<ArrowType> inArrow;
  output String outString;
algorithm
  outString := match(inArrow)
    case NONE() then "none";
    case SOME(ARROWSTANDART()) then "standard";
  end match;
end getArrowTypeString;

protected function getLineTypeString
  input LineType lt;
  output String str;
algorithm
  str := match (lt)
    case LINE() then "line";
    case DASHED() then "dashed";
    case DASHEDDOTTED() then "dashed_dotted";
   end match;
end getLineTypeString;

end GraphML;
