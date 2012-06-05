#pragma once

class IIdaSettings
{
public:
  virtual bool getDenseOutput() =0;
  virtual void setDenseOutput(bool) =0;  
  virtual bool getEventOutput() = 0;
  virtual void setEventOutput(bool)=0;

  virtual ~IIdaSettings(){};
};
