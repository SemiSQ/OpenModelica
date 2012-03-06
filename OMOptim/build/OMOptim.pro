TEMPLATE = app
TARGET = OMOptim

QT +=  core gui svg xml

CONFIG += qt warn_off

CONFIG(debug, debug|release){
    DEFINES+=DEBUG
    # ADD LINK TO OMOPTIM LIB
    LIBS += -L. -lOMOptimd
    TARGET = $$join(TARGET,,,d)
}else{
    LIBS += -L. -lOMOptim
}

win32 {
    # Version numbering (independent from OpenModelica)
    VERSION_HEADER = "../version.h"
    versiontarget.target = $$VERSION_HEADER
    versiontarget.commands = UpdateRevision.bat
    versiontarget.depends += FORCE
    PRE_TARGETDEPS += $$VERSION_HEADER
    QMAKE_EXTRA_TARGETS += versiontarget

    include(../build/OMOptim.windowsconfig.in)
}else {
    include(../build/OMOptim.config)
}

INCLUDEPATH += . \
              .. \
              ../../ \
              ../Core \
              ../GUI \
              ../Vld \
              ../Core/Dymola \
              ../Core/FileData \
              ../Core/Infos \
              ../Core/Modelica \
              ../Core/OMC \
              ../Core/OpenModelica \
              ../Core/Problems \
              ../Core/Tools \
              ../Core/Units \
              ../GUI/Dialogs \
              ../GUI/Plots \
              ../GUI/Resources \
              ../GUI/Scene \
              ../GUI/Tabs \
              ../GUI/Tools \
              ../GUI/Views \
              ../GUI/Widgets \
              ../Core/Optim \
              ../Core/Optim/EA \
              ../Core/Optim/MILP \
              ../Core/Problems/BlockSubs \
              ../Core/Optim/EA/Checkpoints \
              ../Core/Optim/EA/Chromosome \
              ../Core/Optim/EA/Crossover \
              ../Core/Optim/EA/Evaluations \
              ../Core/Optim/EA/Init \
              ../Core/Optim/EA/Monitor \
              ../Core/Optim/EA/Mutations \
              ../Core/Optim/EA/NSGA2 \
              ../Core/Optim/EA/Results \
              ../Core/Optim/EA/SPEA2 \
              ../Core/Optim/EA/SPEA2Adaptative \
              ../Core/Optim/EA/SA1 \
              ../OMOptimBasis/ \
                ../OMOptimBasis/FileData \
                ../OMOptimBasis/GUI \
                ../OMOptimBasis/GUI/Tools \
                ../OMOptimBasis/GUI/Dialogs \
                ../OMOptimBasis/GUI/Widgets \
                ../OMOptimBasis/Infos \
               ../OMOptimBasis/Units \
                ../OMOptimBasis/Tools \
                ../OMOptimBasis/Problems

DEPENDPATH += . \
              .. \
              ../../ \
              ../Core \
              ../GUI \
              ../Vld \
              ../Core/Dymola \
              ../Core/FileData \
              ../Core/Infos \
              ../Core/Modelica \
              ../Core/OMC \
              ../Core/OpenModelica \
              ../Core/Problems \
              ../Core/Tools \
              ../Core/Units \
              ../GUI/Dialogs \
              ../GUI/Plots \
              ../GUI/Resources \
              ../GUI/Scene \
              ../GUI/Tabs \
              ../GUI/Tools \
              ../GUI/Views \
              ../GUI/Widgets \
              ../Core/Optim \
              ../Core/Optim/EA \
              ../Core/Optim/MILP \
              ../Core/Problems/BlockSubs \
              ../Core/Optim/EA/Checkpoints \
              ../Core/Optim/EA/Chromosome \
              ../Core/Optim/EA/Crossover \
              ../Core/Optim/EA/Evaluations \
              ../Core/Optim/EA/Init \
              ../Core/Optim/EA/Monitor \
              ../Core/Optim/EA/Mutations \
              ../Core/Optim/EA/NSGA2 \
              ../Core/Optim/EA/Results \
              ../Core/Optim/EA/SPEA2 \
              ../Core/Optim/EA/SPEA2Adaptative \
              ../Core/Optim/EA/SA1 \
              ../OMOptimBasis/ \
                ../OMOptimBasis/FileData \
                ../OMOptimBasis/GUI \
                ../OMOptimBasis/GUI/Tools \
                ../OMOptimBasis/GUI/Dialogs \
                ../OMOptimBasis/GUI/Widgets \
                ../OMOptimBasis/Infos \
               ../OMOptimBasis/Units \
                ../OMOptimBasis/Tools \
                ../OMOptimBasis/Problems

SOURCES += ../main.cpp

RESOURCES += \
    ../GUI/Resources/OMOptim.qrc

RC_FILE = ../GUI/Resources/rc_omoptim.rc
