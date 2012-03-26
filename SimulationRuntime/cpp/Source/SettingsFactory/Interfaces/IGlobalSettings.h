#pragma once

/*****************************************************************************/
/**

Encapsulation of global simulation settings.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IGlobalSettings
{

public: 
  virtual  ~IGlobalSettings() {}
  ///< Start time of integration (default: 0.0)
  virtual double getStartTime()=0;
  virtual void setStartTime(double)=0;
  ///< End time of integraiton (default: 1.0)
  virtual double getEndTime()=0;
  virtual void getEndTime(double)=0;
  ///< Output step size (default: 20 ms)
  virtual double gethOutput()=0;
  virtual void sethOutput(double)=0;
  ///< Write out results ([false,true]; default: true)
  virtual bool getResultsOutput()=0;
  virtual void setResultsOutput(bool)=0;
  ///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
  virtual bool getInfoOutput()=0;
  virtual void setInfoOutput(bool)=0;
  virtual string  getOutputPath() =0; 
  virtual void setOutputPath(string)=0;   
  virtual string  getSelectedSolver()=0;  
  virtual void setSelectedSolver(string)=0;   
  virtual void load(std::string xml_file)=0;
};
