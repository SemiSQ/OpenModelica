// $Id$
/**
@file ModPlusDymolaCtrl.h
@brief Comments for file documentation.
@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
Company : CEP - ARMINES (France)
http://www-cep.ensmp.fr/english/
@version

*/
#ifndef _MODPLUSDYMOLACTRL_H
#define _MODPLUSDYMOLACTRL_H

#include "ModPlusCtrl.h"
#include "Dymola.h"
#include <limits>

class ModPlusDymolaCtrl :public ModPlusCtrl
{

        enum OutputReadMode
        {
                DSFINAL,
                DSRES
        };

public:
        ModPlusDymolaCtrl(Project* project,ModModelPlus* model,MOomc* oms,QString mmoFolder,QString moFilePath,QString modModelName);
        ~ModPlusDymolaCtrl(void);

        void setMmoFolder(QString);
        ModPlusCtrl::Type type();
        QString name();

        // Variables functions
        bool readOutputVariables(MOVector<Variable> *,QString folder="");
        bool readOutputVariablesDSRES(MOVector<Variable> *,QString _dsresFile);
        bool readOutputVariablesDSFINAL(MOVector<Variable> *,QString _dsfinalFile);
        bool readInitialVariables(MOVector<Variable> *,QString _dsinFile="");

        // Parameters
        void setDefaultParameters();

        // Compile function
        bool createDsin();
        bool isCompiled();
        bool compile(const QStringList & moDependencies=QStringList());

        // Simulate function
        bool simulate(QString tempDir,MOVector<Variable> * updatedVars,MOVector<Variable> * outputVars,
                      QStringList filesTocopy=QStringList(),QStringList moDependencies=QStringList());
        void stopSimulation();
        bool canBeStoped();


private:
        QString _dsinFile;
        QString _dsresFile;
        QString _dsfinalFile;
        OutputReadMode _outputReadMode;
        QProcess _simProcess;

};



#endif
