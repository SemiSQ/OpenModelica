#include "VisualizationWidget.h"

namespace IAEX {

	VisualizationWidget::VisualizationWidget(QWidget *parent) : QWidget(parent)
	{
		this->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding));
		this->setMinimumHeight(300);
		this->setMinimumWidth(500);

		QWidget *visframe = new QWidget();

		visframe->setSizePolicy(QSizePolicy(QSizePolicy::Expanding, QSizePolicy::Expanding));

		simdata_ = new SimulationData();
		simdata_->setFrame(0);

		QFrame *buttonframe = new QFrame();
		QPushButton *playbutton = new QPushButton("Play");
		playbutton->setFixedWidth(32);
		QPushButton *stopbutton = new QPushButton("Stop");
		stopbutton->setFixedWidth(32);
		QPushButton *rewbutton = new QPushButton("Rew");
		rewbutton->setFixedWidth(32);
		label_ = new QLabel();
		label_->setText("0");
		slider_ = new QSlider(Qt::Vertical);
		slider_->setRange(1000*simdata_->get_start_time(), 1000*simdata_->get_end_time());
		slider_->setValue(0);
    currentTime_ = 1000*simdata_->get_start_time();
		QTimer *timer = new QTimer(this);
		// 40 fps
		timer->setInterval(25);

		connect(slider_, SIGNAL(valueChanged(int)),
			this, SLOT(sliderChanged(int)));
		connect(playbutton, SIGNAL(clicked()),
			timer, SLOT(start()));
		connect(stopbutton, SIGNAL(clicked()),
			timer, SLOT(stop()));
		connect(timer, SIGNAL(timeout()),
			this, SLOT(nextFrame()));

		QVBoxLayout *buttonlayout = new QVBoxLayout;
		buttonlayout->addWidget(playbutton);
		buttonlayout->addWidget(stopbutton);
		buttonlayout->addWidget(rewbutton);
		buttonlayout->addWidget(slider_);
		buttonlayout->addWidget(label_);
		buttonlayout->setAlignment(slider_, Qt::AlignHCenter);
		buttonlayout->setAlignment(label_, Qt::AlignHCenter);

		buttonframe->setLayout(buttonlayout);

		eviewer_ = new SoQtExaminerViewer(visframe, NULL, TRUE, SoQtFullViewer::BUILD_NONE);
		eviewer_->setSize(SbVec2s(500,400));
		eviewer_->setSceneGraph(simdata_->getSceneGraph());
		eviewer_->setBackgroundColor(SbColor(0.85f, 0.85f, 0.85f));

		//SoCamera *cam = eviewer_->getCamera();
		//cam->

		QHBoxLayout *framelayout = new QHBoxLayout;
		framelayout->addWidget(visframe);
		framelayout->addWidget(buttonframe);
		this->setLayout(framelayout);

		server = new QTcpServer(this);
		server->setMaxPendingConnections(500);
		activeSocket = 0;


	}

	VisualizationWidget::~VisualizationWidget(void)
	{
	}

	void VisualizationWidget::sliderChanged(int val) {
		currentTime_ = val;
		QString num;
		num.setNum(currentTime_/1000.0);
		label_->setText(num);
		simdata_->setFrame(currentTime_/1000.0);
	}

	void VisualizationWidget::nextFrame() {
		currentTime_ += 25; // FIIIIX!
		if (currentTime_ > 1000*simdata_->get_end_time()) {
			currentTime_ = 0;
		}

		QString num;
		num.setNum(currentTime_/1000.0);
		label_->setText(num);
		slider_->setValue(currentTime_);
		simdata_->setFrame(currentTime_/1000.0);
	}

	void  VisualizationWidget::setServerState(bool listen)
	{
		if(listen)
		{

			if(!getServerState())
				if(!server->listen(QHostAddress::Any, quint16(7778)))
				{
					QTcpSocket s(this);
					s.connectToHost("localhost", quint16(7778));
					if(s.waitForConnected(2000))
					{
						QByteArray b;

						QDataStream ds(&b, QIODevice::WriteOnly);
						ds.setVersion(QDataStream::Qt_4_2);
						ds << quint32(0);
						ds << QString("closeServer");
						ds.device()->seek(0);
						ds << quint32(b.size()-sizeof(quint32));
						s.write(b);
						s.flush();

						s.disconnect();

						qApp->processEvents();
						server->listen(QHostAddress::Any, quint16(7778));
						qApp->processEvents();

					}
				}

				emit newMessage("Listening for connections");

				emit serverState(server->isListening());
				if(!connect(server, SIGNAL(newConnection()), this, SLOT(acceptConnection())))
					QMessageBox::critical(0, QString("fel!"), QString("fel"));
		}
		else
		{
			server->close();
			emit newMessage("Port closed");
			emit serverState(false);
		}
	}

	bool VisualizationWidget::getServerState()
	{
		return server->isListening();
	}

	void VisualizationWidget::acceptConnection()
	{
		while(server && server->hasPendingConnections())
		{
			if( (activeSocket && (activeSocket->state() == QAbstractSocket::UnconnectedState) || !activeSocket))
			{

				emit newMessage("New connection accepted");

				activeSocket = server->nextPendingConnection();
				ds.setDevice(activeSocket);
				ds.setVersion(QDataStream::Qt_4_2);

				blockSize = 0;

				connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));
			}

			qApp->processEvents();
		}
	}

	void VisualizationWidget::getData()	{
		disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);
		connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));

		while(activeSocket->bytesAvailable())
		{
			if (blockSize == 0)
			{
				if (activeSocket->bytesAvailable() < sizeof(quint32))
					return;

				ds >> blockSize;
			}

			if (activeSocket->bytesAvailable() < blockSize)
				return;

			QString command;
			ds >> command;

			if(command == QString("closeServer"))
			{
				setServerState(false);
				activeSocket->disconnect();
				activeSocket->disconnectFromHost();
			}
			else if(command == QString("ptolemyDataStream"))
			{
				simdata_->clear();
				emit newMessage("Recieving streaming data...");
				disconnect(activeSocket, SIGNAL(readyRead()), 0, 0);

				connect(activeSocket, SIGNAL(readyRead()), this, SLOT(readPtolemyDataStream()));
				connect(activeSocket, SIGNAL(disconnected()), this, SLOT(ptolemyDataStreamClosed()));

				variableCount = 0;
				packetSize = 0;

				return;
			}

			blockSize = 0;
		}

		connect(activeSocket, SIGNAL(readyRead()), this, SLOT(getData()));
	}



	void VisualizationWidget::readPtolemyDataStream() {
		QString tmp;
		//qint32 variableCount = 0;
  //  	qint32 packetSize = 0;
		double d;
		quint32 it = 0;

		do
		{
			if(packetSize == 0)
			{
				if(ds.device()->bytesAvailable() >= sizeof(qint32))
					ds >> packetSize;
				else
					return;
			}

			uint a = ds.device()->bytesAvailable();
			if(a < packetSize) {				
				return;
			}


			if(variableCount == 0)
			{
//				variables.clear();
				QString info; 
				ds >> info;
				std::cout << "info: " << info.toStdString() << std::endl;
				QString tmp = info.trimmed();
				bool finished = false;
				while (!finished) {
					QString compound, objname, objtype, params;
					int i,j;
					i = tmp.indexOf("\n");
					int q = tmp.indexOf("Q");
					std::cout << "i: " << i << " & tmp = " << tmp.toStdString() << std::endl;
					if (i < 0) {
						finished = true;
						compound = tmp;
					} else {
						compound = tmp.left(i);
						tmp = tmp.mid(i+1);
					}
					std::cout << "compound: " << compound.toStdString() << std::endl;

					i = compound.indexOf(",");
					j = compound.indexOf(":");
					if (i < 0) {
						continue;
					} else {
						objname = compound.left(i);
						params = compound.mid(i+2,(j-i)-3);
						objtype = compound.mid(j+1);

						std::cout << "name: " << objname.toStdString() 
							<< " & type: " << objtype.toStdString() 
							<< " & params: " << params.toStdString() << std::endl;
						simdata_->addObject(objtype, objname, params);
					}
				}

				ds >> variableCount;
				//std::cout << "variables: " << variableCount << std::endl;

				for(quint32 i = 0; i < variableCount; ++i)
				{
					ds >> tmp;

					//tmp = tmp.trimmed();
					//std::cout << i << ": " << tmp.toStdString() << std::endl;
					//if(variables.find(tmp) != variables.end())
					//	delete variables[tmp];
					//variables[tmp] = new VariableData(tmp, color);
				}
				packetSize = 0;
				continue;
			}

			ds >> variableCount;
			SimulationKeypoint *point = new SimulationKeypoint();

			for(quint32 i = 0; i < variableCount; ++i)
			{
				ds >> tmp;
				ds >> d;
				if (0 == tmp.compare("time")) {
					point->setTime(d);
				} else {
					point->addVar(tmp, d);
				}
//				std::cout << "var: " << tmp.toStdString() << " = " << d << std::endl;
				//variables[tmp]->push_back(d); 
			}
			simdata_->addKeypoint(point);

			packetSize = 0;
			++it;
		}
		while(activeSocket->bytesAvailable() >= sizeof(quint32));

		if(activeSocket->state() != QAbstractSocket::ConnectedState)
			ptolemyDataStreamClosed();
	}	

	void VisualizationWidget::ptolemyDataStreamClosed()	{
		slider_->setRange(1000*simdata_->get_start_time(), 1000*simdata_->get_end_time());
		slider_->setValue(0);
		//for(map<QString, VariableData*>::iterator i = variables.begin(); i != variables.end(); ++i)
		//	variableData.append(i->second);
		//variables.clear();	
		setServerState(false);

		SoCamera *cam = eviewer_->getCamera();
		cam->viewAll(simdata_->getSceneGraph(), eviewer_->getViewportRegion());

		emit newMessage("Connection closed");
	}
}