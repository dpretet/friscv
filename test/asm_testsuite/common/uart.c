#include  <vpi_user.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <errno.h>
#include <fcntl.h>


int socketfd, newsocketfd, portno;
socklen_t clilen;
char buffer[256];
struct sockaddr_in serv_addr, cli_addr;
int flags;


void error(const char *msg)
{
    perror(msg);
    exit(1);
}


static int uart_init_compiletf(char*user_data)
{
    return 0;
}


static int uart_init_calltf(char*user_data)
{
    vpi_printf("Load UART VPI, init the socket\n");

    // open the socket
    socketfd = socket(AF_INET, SOCK_STREAM, 0);
    if (socketfd < 0)
        error("ERROR: failed to open a TCP socket");
    flags = fcntl(socketfd, F_GETFL);
    if (flags<0)
        error("ERROR: can't get flag on TCP socket");

    if (fcntl(socketfd, F_SETFL, flags | O_NONBLOCK))
        error("ERROR: couldn't set the socket as non-blocking");

    // initialize the buffer
    // bzero((char *) &serv_addr, sizeof(serv_addr));

    // setup the socket
    portno = 33334;
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    serv_addr.sin_port = htons(portno);

    if (bind(socketfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0)
        error("ERROR on binding");

    listen(socketfd, 100);
    return 0;
}

static int uart_close_compiletf(char*user_data)
{
    return 0;
}

static int uart_close_calltf(char*user_data)
{
    vpi_printf("Terminate UART VPI and its socket\n");

    close(socketfd);
    return 0;
}

static int uart_listen_compiletf(char*user_data)
{
    return 0;
}

static int uart_listen_calltf(char*user_data)
{
    vpi_printf("Listen the socket\n");

    bzero(buffer,256);
    int client_socket_fd = accept(socketfd, NULL, NULL);
    if (client_socket_fd == -1) {
        if (errno == EWOULDBLOCK) {
            printf("No pending connections; sleeping for one second.\n");
            sleep(1);
        } else {
            perror("error when accepting connection");
            exit(1);
        }
    } else {
        int n = read(newsocketfd,buffer,255);
        if (n < 0) {
            printf("Nothing to read from socket");
        } else {
            printf("Here is the message: %s\n",buffer);
        }
        char msg[] = "hello\n";
        printf("Got a connection; writing 'hello' then closing.\n");
        send(client_socket_fd, msg, sizeof(msg), 0);
        close(client_socket_fd);
    }
    return 0;
}

static int uart_send_compiletf(char*user_data)
{
    return 0;
}

static int uart_send_calltf(char* user_data)
{
    vpi_printf("Send data to the socket");

    char msg[] = "hello\n";
    send(socketfd, msg, sizeof(msg), 0);
    return 0;
}

void uart_init_register()
{
    s_vpi_systf_data tf_data;

    tf_data.type      = vpiSysTask;
    tf_data.tfname    = "$uart_init";
    tf_data.calltf    = uart_init_calltf;
    tf_data.compiletf = uart_init_compiletf;
    tf_data.sizetf    = 0;
    tf_data.user_data = 0;
    vpi_register_systf(&tf_data);
}

void uart_send_register()
{
    s_vpi_systf_data tf_data;

    tf_data.type      = vpiSysTask;
    tf_data.tfname    = "$uart_send";
    tf_data.calltf    = uart_send_calltf;
    tf_data.compiletf = uart_send_compiletf;
    tf_data.sizetf    = 0;
    tf_data.user_data = 0;
    vpi_register_systf(&tf_data);
}

void uart_listen_register()
{
    s_vpi_systf_data tf_data;

    tf_data.type      = vpiSysTask;
    tf_data.tfname    = "$uart_listen";
    tf_data.calltf    = uart_listen_calltf;
    tf_data.compiletf = uart_listen_compiletf;
    tf_data.sizetf    = 0;
    tf_data.user_data = 0;
    vpi_register_systf(&tf_data);
}

void uart_close_register()
{
    s_vpi_systf_data tf_data;

    tf_data.type      = vpiSysTask;
    tf_data.tfname    = "$uart_close";
    tf_data.calltf    = uart_close_calltf;
    tf_data.compiletf = uart_close_compiletf;
    tf_data.sizetf    = 0;
    tf_data.user_data = 0;
    vpi_register_systf(&tf_data);
}

void (*vlog_startup_routines[])() = {
    uart_init_register,
    uart_close_register,
    0
};
