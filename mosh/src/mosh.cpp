/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <cstdio>
#include <strstream>

#include <readline/readline.h>
#include <readline/history.h>

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netdb.h>

void open_socket(char* hostname, int port);

char * check_moshhome(void);

void init_sockaddr (struct sockaddr_in *name,
                             const char *hostname,
                             int port);
int main(int argc, char* argv[])
{
  char buf[40000];
  
  
  char * moshhome=check_moshhome();
  
  if (argc==1) 
    {
      // Starting background server.
      char systemstr[255];
      sprintf(systemstr,"%s/../modeq/modeq +d=interactive > %s/error.log &",
	      moshhome,moshhome);
      int res = system(systemstr);
      cout << "Started server..." << endl;
    }
  
  if (argc > 2)
    {
      std::cerr << "Incorrect number of arguments\n";
      return EXIT_FAILURE;
    }
  
  std::cout << "Open Source Modelica 0.1" << endl;
  std::cout << "Copyright 2002, PELAB, Linkoping University" << endl;
      
  int port=29500;
  
  char* hostname ="localhost";
  // TODO: add port nr. and host as command line option
  
  
 /* Create the socket. */
  int sock = socket (PF_INET, SOCK_STREAM, 0);
  if (sock < 0)
    {
      perror ("socket (client)");
      exit (EXIT_FAILURE);
    }

  /* Connect to the server. */
  struct sockaddr_in servername;
  init_sockaddr (&servername, hostname, port);
  if (0 > connect (sock,
                   (struct sockaddr *) &servername,
                   sizeof (servername)))
    {
      perror ("connect (client)");
      exit (EXIT_FAILURE);
    }

  bool done=false;	
  while (!done) {
    char* line = readline(">>> ");
    if (strcmp(line,"quit()") == 0) {
      done =true;
    }
    int nbytes = write(sock,line,strlen(line)+1);
    int recvbytes = read(sock,buf,40000);
    cout << buf;
  }
  close (sock);  
  return EXIT_SUCCESS;
}

char * check_moshhome(void)
{
  char *str;
  
  str=getenv("MOSHHOME");
  if (str == NULL) {
    printf("Error, MOSHHOME not set. Set MOSHHOME to the directory where mosh resides (top dir)\n");
    exit(1);
  }
  return str;
}

void
init_sockaddr (struct sockaddr_in *name,
               const char *hostname,
               int port)
{
  struct hostent *hostinfo;

  name->sin_family = AF_INET;
  name->sin_port = htons (port);
  hostinfo = gethostbyname (hostname);
  if (hostinfo == NULL)
    {
      fprintf (stderr, "Unknown host %s.\n", hostname);
      exit (EXIT_FAILURE);
    }
  name->sin_addr = *(struct in_addr *) hostinfo->h_addr;
}
