#pragma once

#include "../Interfaces/INewtonSettings.h"

class NewtonSettings :public INewtonSettings
{
public:
	NewtonSettings();
		/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
	virtual long int    getNewtMax();					
	virtual void		setNewtMax(long int);	
	/* Relative Toleranz f�r die Newtoniteration (default: 1e-6)*/
	virtual double		getRtol();
	virtual void		setRtol(double);				
	/*Absolute Toleranz f�r die Newtoniteration (default: 1e-6)*/
	virtual double		getAtol();						
	virtual void		setAtol(double);				
	/*D�mpfungsfaktor (default: 0.9)*/
	virtual double	    getDelta();							
	virtual void	    setDelta(double);
	virtual void load(string);
private:
	long int    iNewt_max;					///< max. Anzahl an Newtonititerationen pro Schritt (default: 25)

	double		dRtol;						///< Relative Toleranz f�r die Newtoniteration (default: 1e-6)
	double		dAtol;						///< Absolute Toleranz f�r die Newtoniteration (default: 1e-6)
	double	    dDelta;						///< D�mpfungsfaktor (default: 0.9)
};
