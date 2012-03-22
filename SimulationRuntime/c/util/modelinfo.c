/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "omc_error.h"
#include "simulation_data.h"
#include "rtclock.h"
#include "modelinfo.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <assert.h>

/* UNDEF to debug the gnuplot file
#define NO_PIPE
*/

/* Returns -1 if the file was not found */
static size_t fileSize(const char *filename) {
  size_t sz = -1;
  FILE *f = fopen(filename, "rb");
  if (f) {
    fseek(f, 0, SEEK_END);
    sz = ftell(f);
    fclose(f);
  }
  return sz;
}

static void indent(FILE *fout, int n) {
  while (n--) fputc(' ', fout);
}

static void printPlotCommand(FILE *plt, const char *plotFormat, const char *title, const char *prefix, int numFnsAndBlocks, int i, int id, const char *idPrefix) {
  const char *format = "plot \"%s_prof.data\" binary format=\"%%*uint32%%2double%%*%duint32%%%ddouble\" using 1:($%d>1e-9 ? $%d : 1e-30) w l lw 1\n";
  const char *formatCount = "plot \"%s_prof.data\" binary format=\"%%*uint32%%*2double%%%duint32%%*%ddouble\" using %d w l lw 1\n";
  unsigned long nmin = 0, nmax = 0;
  double ymin = 0.0, ymax = 0.0;
  if (!plt) return;
  /* PNG */
  fputs("set terminal png size 32,32\n", plt);
  fprintf(plt, "set output \"%s_prof.%s%d.thumb.png\"\n", prefix, idPrefix, id);
  fprintf(plt, "set title\n");
  fprintf(plt, "set xlabel\n");
  fprintf(plt, "set ylabel\n");
  fprintf(plt, "set log y\n");
  fprintf(plt, format, prefix, numFnsAndBlocks, numFnsAndBlocks, 3+i, 3+i);
  fprintf(plt, "set nolog xy\n");
  if (i >= 0) {
    nmin = rt_ncall_min(SIM_TIMER_FIRST_FUNCTION + i);
    nmax = rt_ncall_max(SIM_TIMER_FIRST_FUNCTION + i);
    ymin = nmin==0 ? -0.01 : nmin*0.99;
    ymax = nmax==0 ?  0.01 : nmax*1.01;

    /*
     * Note: We set the yrange here because otherwise we get warnings if the
     * number of calls are the same in every time step (i.e. autoscale thinks
     * the range is [3:3])
     */
    fprintf(plt, "set yrange [%f:%f]\n", ymin, ymax);
    fprintf(plt, "set output \"%s_prof.%s%d_count.thumb.png\"\n", prefix, idPrefix, id);
    fprintf(plt, formatCount, prefix, numFnsAndBlocks, numFnsAndBlocks, i+1);
    fprintf(plt, "set yrange [*:*]\n");
  }

  /* SVG */
  fprintf(plt, "set terminal %s\n", plotFormat);
  fprintf(plt, "set title \"%s\"\n", title);
  fprintf(plt, "set xlabel \"Global step at time\"\n");
  fprintf(plt, "set ylabel \"Execution time [s]\"\n");
  fprintf(plt, "set output \"%s_prof.%s%d.%s\"\n", prefix, idPrefix, id, plotFormat);
  fprintf(plt, "set log y\n");
  fprintf(plt, format, prefix, numFnsAndBlocks, numFnsAndBlocks, 3+i, 3+i);
  fprintf(plt, "set nolog xy\n");
  if (i >= 0) {
    fprintf(plt, "set yrange [%f:%f]\n", ymin, ymax);
    fprintf(plt, "set xlabel \"Global step number\"\n");
    fprintf(plt, "set ylabel \"Execution count\"\n");
    fprintf(plt, "set output \"%s_prof.%s%d_count.%s\"\n", prefix, idPrefix, id, plotFormat);
    fprintf(plt, formatCount, prefix, numFnsAndBlocks, numFnsAndBlocks, i+1);
    fprintf(plt, "set yrange [*:*]\n");
  }
}

static void printStrXML(FILE *fout, const char *str)
{
  while (*str) {
  switch (*str) {
  case '<': fputs("&lt;",fout);break;
  case '>': fputs("&gt;",fout);break;
  case '\'': fputs("&apos;",fout);break;
  case '"': fputs("&quot;",fout);break;
  /* case '\\': fputs("\\\\",fout);break; */
  default: fputc(*str,fout); break;
  }
  str++;
  }
}

static void printInfoTag(FILE *fout, int level, const FILE_INFO info) {
  indent(fout,level);
  fprintf(fout, "<info filename=\"");
  printStrXML(fout, info.filename);
  fprintf(fout, "\" startline=\"%d\" startcol=\"%d\" endline=\"%d\" endcol=\"%d\" readonly=\"%s\" />\n", info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly ? "readonly" : "writable");
}

static void printVar(FILE *fout, int level, VAR_INFO* info) {

  indent(fout,level);
  fprintf(fout, "<variable id=\"var%d\" name=\"", info->id);
  printStrXML(fout, info->name);
  fprintf(fout, "\" comment=\"");
  printStrXML(fout, info->comment);
  fprintf(fout, "\">\n");
  printInfoTag(fout, level+2, info->info);
  indent(fout,level);
  fprintf(fout, "</variable>\n");
}


static void printFunctions(FILE *fout, FILE *plt, const char *plotFormat, const char *modelFilePrefix, DATA *data, const struct FUNCTION_INFO *funcs) {
  int i;
  for (i=0; i<data->modelData.nFunctions; i++) {
    printPlotCommand(plt, plotFormat, funcs[i].name, modelFilePrefix, data->modelData.nFunctions+data->modelData.nProfileBlocks, i, funcs[i].id, "fun");
    rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    indent(fout,2);
    fprintf(fout, "<function id=\"fun%d\">\n", funcs[i].id);
    indent(fout,4);fprintf(fout, "<name>");printStrXML(fout, funcs[i].name);fprintf(fout,"</name>\n");
    indent(fout,4);fprintf(fout, "<ncall>%d</ncall>\n", (int) rt_ncall_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<time>%.9f</time>\n",rt_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<maxTime>%.9f</maxTime>\n",rt_max_accumulated(i + SIM_TIMER_FIRST_FUNCTION));
    printInfoTag(fout, 6, funcs[i].info);
    indent(fout,2);
    fprintf(fout, "</function>\n");
  }
}

static void printProfileBlocks(FILE *fout, FILE *plt, const char *plotFormat, DATA *data) {
  int i;
  for (i = data->modelData.nFunctions; i < data->modelData.nFunctions + data->modelData.nProfileBlocks; i++) {
    const struct EQUATION_INFO *eq = &(data->modelData.equationInfo[data->modelData.equationInfo_reverse_prof_index[i-data->modelData.nFunctions]]);
    printPlotCommand(plt, plotFormat, eq->name, data->modelData.modelFilePrefix, data->modelData.nFunctions+data->modelData.nProfileBlocks, i, eq->id, "eq");
    rt_clear(i + SIM_TIMER_FIRST_FUNCTION);
    indent(fout,2);fprintf(fout, "<profileblock>\n");
    indent(fout,4);fprintf(fout, "<ref refid=\"eq%d\"/>\n", (int) eq->id);
    indent(fout,4);fprintf(fout, "<ncall>%d</ncall>\n", (int) rt_ncall_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<time>%.9f</time>\n", rt_total(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,4);fprintf(fout, "<maxTime>%.9f</maxTime>\n",rt_max_accumulated(i + SIM_TIMER_FIRST_FUNCTION));
    indent(fout,2);fprintf(fout, "</profileblock>\n");
  }
}

static void printEquations(FILE *fout, int n, EQUATION_INFO *eqns) {
  int i,j;
  for (i=0; i<n; i++) {
    indent(fout,2);fprintf(fout, "<equation id=\"eq%d\" name=\"", eqns[i].id);printStrXML(fout,eqns[i].name);fprintf(fout,"\">\n");
    indent(fout,4);fprintf(fout, "<refs>\n");
    for (j=0; j<eqns[i].numVar; j++) {
      indent(fout,6);fprintf(fout, "<ref refid=\"var%d\" />\n", eqns[i].vars[j]->id);
    }
    indent(fout,4);fprintf(fout, "</refs>\n");
    indent(fout,2);fprintf(fout, "</equation>\n");
  }
}

static void printProfilingDataHeader(FILE *fout, DATA *data) {
  char *filename;
  int i;
  
  filename = malloc(strlen(data->modelData.modelFilePrefix) + 15);
  sprintf(filename, "%s_prof.data", data->modelData.modelFilePrefix);
  indent(fout, 2); fprintf(fout, "<filename>");printStrXML(fout,filename);fprintf(fout,"</filename>\n");
  indent(fout, 2); fprintf(fout, "<filesize>%ld</filesize>\n", (long) fileSize(filename));
  free(filename);
  
  indent(fout, 2); fprintf(fout, "<format>\n");
  indent(fout, 4); fprintf(fout, "<uint32>step</uint32>\n");
  indent(fout, 4); fprintf(fout, "<double>time</double>\n");
  indent(fout, 4); fprintf(fout, "<double>cpu time</double>\n");
  for (i = 0; i < data->modelData.nFunctions; i++) {
    const char *name = data->modelData.functionNames[i].name;
    indent(fout, 4); fprintf(fout, "<uint32>");printStrXML(fout,name);fprintf(fout, " (calls)</uint32>\n");
  }
  for (i = 0; i < data->modelData.nProfileBlocks; i++) {
    const char *name = data->modelData.equationInfo[data->modelData.equationInfo_reverse_prof_index[i]].name;
    indent(fout, 4); fprintf(fout, "<uint32>");printStrXML(fout,name);fprintf(fout, " (calls)</uint32>\n");
  }
  for (i = 0; i < data->modelData.nFunctions; i++) {
    const char *name = data->modelData.functionNames[i].name;
    indent(fout, 4); fprintf(fout, "<double>");printStrXML(fout,name);fprintf(fout, " (cpu time)</double>\n");
  }
  for (i = 0; i < data->modelData.nProfileBlocks; i++) {
    const char *name = data->modelData.equationInfo[data->modelData.equationInfo_reverse_prof_index[i]].name;
    indent(fout, 4); fprintf(fout, "<double>");printStrXML(fout,name);fprintf(fout, " (cpu time)</double>\n");
  }
  indent(fout, 2); fprintf(fout, "</format>\n");
}

int printModelInfo(DATA *data, const char *filename, const char *plotfile, const char *plotFormat, const char *method, const char *outputFormat, const char *outputFilename) {
  static char buf[256];
  FILE *fout = fopen(filename, "w");
  FILE *plotCommands;
  time_t t;
  int i;
#if defined(__MINGW32__) || defined(_MSC_VER) || defined(NO_PIPE)
  plotCommands = fopen(plotfile, "w");
#else
  plotCommands = popen("gnuplot", "w");
#endif
  if (!plotCommands) {
    WARNING1("Plots of profiling data were disabled: %s\n", strerror(errno));
  }
  if (!fout) {
    THROW2("Failed to open %s: %s\n", filename, strerror(errno));
  }
  if (plotCommands) {
    fputs("set terminal svg\n", plotCommands);
    fputs("set nokey\n", plotCommands);
    /* The column containing the time spent to calculate each step */
    printPlotCommand(plotCommands, plotFormat, "Execution time of global steps", data->modelData.modelFilePrefix, data->modelData.nFunctions+data->modelData.nProfileBlocks, -1, 999, "");
  }
  /* The doctype is needed for id() lookup to work properly */
  fprintf(fout, "<!DOCTYPE doc [\
  <!ELEMENT simulation (modelinfo, variables, functions, equations)>\
  <!ATTLIST variable id ID #REQUIRED>\
  <!ELEMENT equation (refs)>\
  <!ATTLIST equation id ID #REQUIRED>\
  <!ELEMENT profileblocks (profileblock*)>\
  <!ELEMENT profileblock (refs, ncall, time, maxTime)>\
  <!ELEMENT refs (ref*)>\
  <!ATTLIST ref refid IDREF #REQUIRED>\
  ]>\n");
  if (time(&t) < 0) {
    WARNING1("time() failed: %s", strerror(errno));
    fclose(fout);
    return 1;
  }
  if (!strftime(buf, 250, "%Y-%m-%d %H:%M:%S", localtime(&t))) {
    WARNING("strftime() failed");
    fclose(fout);
    return 1;
  }
  fprintf(fout, "<simulation>\n");
  fprintf(fout, "<modelinfo>\n");
  indent(fout, 2); fprintf(fout, "<name>");printStrXML(fout,data->modelData.modelName);fprintf(fout,"</name>\n");
  indent(fout, 2); fprintf(fout, "<prefix>");printStrXML(fout,data->modelData.modelFilePrefix);fprintf(fout,"</prefix>\n");
  indent(fout, 2); fprintf(fout, "<date>");printStrXML(fout,buf);fprintf(fout,"</date>\n");
  indent(fout, 2); fprintf(fout, "<method>");printStrXML(fout,data->simulationInfo.solverMethod);fprintf(fout,"</method>\n");
  indent(fout, 2); fprintf(fout, "<outputFormat>");printStrXML(fout,data->simulationInfo.outputFormat);fprintf(fout,"</outputFormat>\n");
  indent(fout, 2); fprintf(fout, "<outputFilename>");printStrXML(fout,outputFilename);fprintf(fout,"</outputFilename>\n");
  indent(fout, 2); fprintf(fout, "<outputFilesize>%ld</outputFilesize>\n", (long) fileSize(outputFilename));
  indent(fout, 2); fprintf(fout, "<overheadTime>%f</overheadTime>\n", rt_accumulated(SIM_TIMER_OVERHEAD));
  indent(fout, 2); fprintf(fout, "<preinitTime>%f</preinitTime>\n", rt_accumulated(SIM_TIMER_PREINIT));
  indent(fout, 2); fprintf(fout, "<initTime>%f</initTime>\n", rt_accumulated(SIM_TIMER_INIT));
  indent(fout, 2); fprintf(fout, "<eventTime>%f</eventTime>\n", rt_accumulated(SIM_TIMER_EVENT));
  indent(fout, 2); fprintf(fout, "<outputTime>%f</outputTime>\n", rt_accumulated(SIM_TIMER_OUTPUT));
  indent(fout, 2); fprintf(fout, "<linearizeTime>%f</linearizeTime>\n", rt_accumulated(SIM_TIMER_LINEARIZE));
  indent(fout, 2); fprintf(fout, "<totalTime>%f</totalTime>\n", rt_accumulated(SIM_TIMER_TOTAL));
  indent(fout, 2); fprintf(fout, "<totalStepsTime>%f</totalStepsTime>\n", rt_total(SIM_TIMER_STEP));
  indent(fout, 2); fprintf(fout, "<numStep>%d</numStep>\n", (int) rt_ncall_total(SIM_TIMER_STEP));
  indent(fout, 2); fprintf(fout, "<maxTime>%.9f</maxTime>\n", rt_max_accumulated(SIM_TIMER_STEP));
  fprintf(fout, "</modelinfo>\n");

  fprintf(fout, "<profilingdataheader>\n");
  printProfilingDataHeader(fout, data);
  fprintf(fout, "</profilingdataheader>\n");

  fprintf(fout, "<variables>\n");
  for(i=0;i<data->modelData.nVariablesReal;++i){
    printVar(fout, 2, &(data->modelData.realVarsData[i].info));
  }
  for(i=0;i<data->modelData.nParametersReal;++i){
    printVar(fout, 2, &data->modelData.realParameterData[i].info);
  }
  for(i=0;i<data->modelData.nVariablesInteger;++i){
    printVar(fout, 2, &data->modelData.integerVarsData[i].info);
  }
  for(i=0;i<data->modelData.nParametersInteger;++i){
    printVar(fout, 2, &data->modelData.integerParameterData[i].info);
  }
  for(i=0;i<data->modelData.nVariablesBoolean;++i){
    printVar(fout, 2, &data->modelData.booleanVarsData[i].info);
  }
  for(i=0;i<data->modelData.nParametersBoolean;++i){
    printVar(fout, 2, &data->modelData.booleanParameterData[i].info);
  }
  for(i=0;i<data->modelData.nVariablesString;++i){
    printVar(fout, 2, &data->modelData.stringVarsData[i].info);
  }
  for(i=0;i<data->modelData.nParametersString;++i){
    printVar(fout, 2, &data->modelData.stringParameterData[i].info);
  }
  fprintf(fout, "</variables>\n");

  fprintf(fout, "<functions>\n");
  printFunctions(fout, plotCommands, plotFormat, data->modelData.modelFilePrefix, data, data->modelData.functionNames);
  fprintf(fout, "</functions>\n");

  fprintf(fout, "<equations>\n");
  printEquations(fout, data->modelData.nEquations, data->modelData.equationInfo);
  fprintf(fout, "</equations>\n");

  fprintf(fout, "<profileblocks>\n");
  printProfileBlocks(fout, plotCommands, plotFormat, data);
  fprintf(fout, "</profileblocks>\n");

  fprintf(fout, "</simulation>\n");

  fclose(fout);
  if (plotCommands) {
    char *omhome = NULL;
    char *buf = NULL;
    int genHtmlRes;
    omhome = getenv("OPENMODELICAHOME");
    buf = (char*)malloc(230 + 2*strlen(plotfile) + 2*(omhome ? strlen(omhome) : 0));
    assert(buf);
#if defined(__MINGW32__) || defined(_MSC_VER) || defined(NO_PIPE)
    if (omhome) {
#if defined(__MINGW32__) || defined(_MSC_VER)
      sprintf(buf, "%s/lib/omc/libexec/gnuplot/binary/gnuplot.exe %s", omhome, plotfile);
#else
      sprintf(buf, "gnuplot %s", plotfile);
#endif
      fclose(plotCommands);
      if (0 != system(buf)) {
        WARNING1("Plot command failed: %s\n", buf);
      }
    }
#else
    if (0 != pclose(plotCommands)) {
      WARNING("Warning: Plot command failed\n");
    }
#endif
    if (omhome) {
#if defined(__MINGW32__) || defined(_MSC_VER)
      char *xsltproc;
      sprintf(buf, "%s/lib/omc/libexec/xsltproc/xsltproc.exe", omhome);
      xsltproc = strdup(buf);
#else
      const char *xsltproc = "xsltproc";
#endif
      sprintf(buf, "%s -o %s_prof.html %s/share/omc/scripts/default_profiling.xsl %s_prof.xml", xsltproc, data->modelData.modelFilePrefix, omhome, data->modelData.modelFilePrefix);
#if defined(__MINGW32__) || defined(_MSC_VER)
      free(xsltproc);
#endif
      genHtmlRes = system(buf);
    } else {
      strcpy(buf, "OPENMODELICAHOME missing");
      genHtmlRes = 1;
    }
    if (genHtmlRes)
      WARNING1("Failed to generate html version of profiling results: %s\n", buf);
    INFO2("Time measurements are stored in %s_prof.html (human-readable) and %s_prof.xml (for XSL transforms or more details)\n", data->modelData.modelFilePrefix, data->modelData.modelFilePrefix);
    free(buf);
  }
  return 0;
}
