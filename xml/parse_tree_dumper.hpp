#ifndef PARSE_TREE_DUMPER_H_
#define PARSE_TREE_DUMPER_H_

// adrpo disabling warnings
#pragma warning( disable : 4267)  // Disable warning messages C4267 
// disable: 'initializing' : conversion from 'size_t' to 'int', possible loss of data

#pragma warning( disable : 4231)  // Disable warning messages C4231 
// disable: nonstandard extension used : 'extern' before template explicit instantiation

#pragma warning( disable : 4101)  // Disable warning messages C4101 
// disable: warning C4101: 'pe' : unreferenced local variable


#include "antlr/CommonAST.hpp"
#include <iostream>


class parse_tree_dumper
{
private:
    int fIndent;
    static char c1;
    static char c2;

    static char c;
    static char prefix[];

    static int indentSize;

    std::ostream &out;
  
public:
    parse_tree_dumper(std::ostream& os) : out(os){
	fIndent = 0;
    }
  
    void flush()
    {
	out.flush();
    }

    void toIndent()
    {
	if (fIndent <= 0)
	    return;
	for (int i=0; i<fIndent; i++)
	{
	    c = (c == c1 ? c2 : c1);
	    out << c;
	}
    }

    void indent(int i)
    {
	fIndent += i;
    }

    void dump(antlr::RefAST ast)
    {
	toIndent();
	out << prefix;
	if (ast == 0)
	{
	    out << "<NULL>";
	}
	else
	{
	    out << ast->toString();
	    if (ast->getFirstChild() != 0)
	    {
		out << " {" << std::endl;
		indent(indentSize);
		dump(ast->getFirstChild());
		indent(-indentSize);
		toIndent();
		out << "}" << std::endl;
	    }
	    else
	    {
		out << std::endl;
	    }
	    if (ast->getNextSibling() != 0)
	    {
		dump(ast->getNextSibling());
	    }
	}
    }
    void dump_dot(antlr::RefAST ast)
    {
	out << "digraph G {\n";
	dump_dot_recursive(ast);
	out << "}\n";	
    }
    
    void dump_dot_recursive(antlr::RefAST ast)
    {
	if (ast == 0)
	{
	    out << "\n";
	}
	else
	{
	    out << "\"" << ast.get() << "\" [label=\"" << ast->toString() << "\" shape=\"box\"];\n";
	    antlr::RefAST current_ast = ast->getFirstChild();
	    
	    while (current_ast != 0)
	    {
		dump_dot_recursive(current_ast);		
		out << "\t\"" <<  ast.get() << "\" -> \"" << current_ast.get() << "\";\n";

		current_ast = current_ast->getNextSibling();		
	    }
	}
    }

};

#endif 
