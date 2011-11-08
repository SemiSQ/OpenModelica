/****************************************************************************
**
** Copyright (C) 1992-2007 Trolltech ASA. All rights reserved.
**
** This file is part of the QtGui module of the Qt Toolkit.
**
** This file may be used under the terms of the GNU General Public
** License version 2.0 as published by the Free Software Foundation
** and appearing in the file LICENSE.GPL included in the packaging of
** this file.  Please review the following information to ensure GNU
** General Public Licensing requirements will be met:
** http://trolltech.com/products/qt/licenses/licensing/opensource/
**
** If you are unsure which license is appropriate for your use, please
** review the following information:
** http://trolltech.com/products/qt/licenses/licensing/licensingoverview
** or contact the sales department at sales@trolltech.com.
**
** In addition, as a special exception, Trolltech gives you certain
** additional rights. These rights are described in the Trolltech GPL
** Exception version 1.0, which can be found at
** http://www.trolltech.com/products/qt/gplexception/ and in the file
** GPL_EXCEPTION.txt in this package.
**
** In addition, as a special exception, Trolltech, as the sole copyright
** holder for Qt Designer, grants users of the Qt/Eclipse Integration
** plug-in the right for the Qt/Eclipse Integration to link to
** functionality provided by Qt Designer and its related libraries.
**
** Trolltech reserves all rights not expressly granted herein.
**
** Trolltech ASA (c) 2007
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
****************************************************************************/

#ifndef QRGB_H
#define QRGB_H

#include <QtCore/qglobal.h>

QT_BEGIN_HEADER

QT_MODULE(Gui)

typedef unsigned int QRgb;                        // RGB triplet

const QRgb  RGB_MASK    = 0x00ffffff;                // masks RGB values

Q_GUI_EXPORT_INLINE int qRed(QRgb rgb)                // get red part of RGB
{ return ((rgb >> 16) & 0xff); }

Q_GUI_EXPORT_INLINE int qGreen(QRgb rgb)                // get green part of RGB
{ return ((rgb >> 8) & 0xff); }

Q_GUI_EXPORT_INLINE int qBlue(QRgb rgb)                // get blue part of RGB
{ return (rgb & 0xff); }

Q_GUI_EXPORT_INLINE int qAlpha(QRgb rgb)                // get alpha part of RGBA
{ return ((rgb >> 24) & 0xff); }

Q_GUI_EXPORT_INLINE QRgb qRgb(int r, int g, int b)// set RGB value
{ return (0xff << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff); }

Q_GUI_EXPORT_INLINE QRgb qRgba(int r, int g, int b, int a)// set RGBA value
{ return ((a & 0xff) << 24) | ((r & 0xff) << 16) | ((g & 0xff) << 8) | (b & 0xff); }

Q_GUI_EXPORT_INLINE int qGray(int r, int g, int b)// convert R,G,B to gray 0..255
{ return (r*11+g*16+b*5)/32; }

Q_GUI_EXPORT_INLINE int qGray(QRgb rgb)                // convert RGB to gray 0..255
{ return qGray(qRed(rgb), qGreen(rgb), qBlue(rgb)); }

Q_GUI_EXPORT_INLINE bool qIsGray(QRgb rgb)
{ return qRed(rgb) == qGreen(rgb) && qRed(rgb) == qBlue(rgb); }

QT_END_HEADER

#endif // QRGB_H
