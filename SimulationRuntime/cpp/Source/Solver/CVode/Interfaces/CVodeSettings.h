#pragma once

#include "../../Implementation/SolverSettings.h"


						/*****************************************************************************/
						/**

						Klasse zur Kapselung der Parameter (Einstellungen) f�r Euler.
						Hier werden default-Einstellungen entsprechend der allgemeinen Simulations-
						einstellugnen gemacht, diese k�nnen �berpr�ft und ev. Fehleinstellungen korrigiert 
						werden.
						\date     Montag, 1. August 2005
						\author   Daniel Kanth
						$Id: CVodeSettings.h,v 1.1 2007/04/25 02:18:37 danikant Exp $
						\par	Synopsis:
						CVodeSettings(&System, &Global);
						*/
						/*****************************************************************************
						Copyright (c) 2004, Bosch Rexroth AG, All rights reserved
						*****************************************************************************/
						class CVodeSettings : public SolverSettings
						{

						public:
							CVodeSettings(IGlobalSettings* globalSettings)
								: SolverSettings		(globalSettings)
								, iMethod				(EULERFORWARD)
								, dIterTol				(1e-8)
								,bContinue				(false)
								, iJacUpdate				(0)
							{
							};

							/// Enum f�r Wahl der Methode
							enum EulerMethod
							{
								EULERFORWARD,  			///< Euler Vorw�rts
								EULERBACKWARD,			///< Euler R�ckw�rts (wie Euler-Cauchy, aber impl.)
								
							};

							int 
								iMethod;				///< Verfahrensauswahl ([0,1,2,3,4,5]; default: 0)

							
							double
								dIterTol;				///< Toleranz f�r die Iteration (Der Steigungen werden iteriert, bis Steigungs�nderung < IterTol)

							bool 
								bContinue;             ///< Soll nach Fehler in Newtoniteration weiter gerechnet werden oder abgebrochen werden
							int 
								iJacUpdate;			   //Anzahl Schritte wann Jacobi Matrix aktualisiert werden soll	

						};
					}
				}
			}
		}
	}
}