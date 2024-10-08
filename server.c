/* run using ./server <port> */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <netinet/in.h>

#include <pthread.h>

void error(char *msg) {
  perror(msg);
  exit(1);
}

void *start_function(void *sockfd) {
  int newsockfd = *(int *)sockfd;
  char buffer[256];
  bzero(buffer, 256);

  /* read message from client */
  int n = read(newsockfd, buffer, 255);
  if (n < 0)
    error("ERROR reading from socket");

  printf("Here is the message: %s", buffer);
	sleep (5);
	
	  /* send reply to client */
  n = write(newsockfd, "I got your message", 18);

  if (n < 0)
    error("ERROR writing to socket");

  close(newsockfd);
  pthread_exit(NULL);
}

int main(int argc, char *argv[]) {
  int sockfd, newsockfd, portno;
  socklen_t clilen;
  struct sockaddr_in serv_addr, cli_addr;
  int n;

  if (argc < 2) {
    fprintf(stderr, "ERROR, no port provided\n");
    exit(1);
  }

  /* create socket */

  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0)
    error("ERROR opening socket");

  /* fill in port number to listen on. IP address can be anything (INADDR_ANY)
   */

  bzero((char *)&serv_addr, sizeof(serv_addr));
  portno = atoi(argv[1]);
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = INADDR_ANY;
  serv_addr.sin_port = htons(portno);

  /* bind socket to this port number on this machine */

  if (bind(sockfd, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0)
    error("ERROR on binding");

  /* listen for incoming connection requests */

  listen(sockfd, 5);
  clilen = sizeof(cli_addr);

  /* accept a new request, create a newsockfd */

  while (1) {
    newsockfd = accept(sockfd, (struct sockaddr *)&cli_addr, &clilen);
    if (newsockfd < 0)
      error("ERROR on accept");
    pthread_t thread;
    if (pthread_create(&thread, NULL, start_function, &newsockfd) != 0)
      printf("Failed to create Thread\n");
  }

  return 0;
}
