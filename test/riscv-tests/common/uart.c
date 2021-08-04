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


int socketfd;
int portno;
char buffer[256];
struct sockaddr_in addr;
int flags;


///////////////////////////////////////////////////////////////////////////////
// Error function used in the other to exit on error
///////////////////////////////////////////////////////////////////////////////
void error(const char *msg)
{
    vpi_printf("%s", msg);
    exit(1);
}


///////////////////////////////////////////////////////////////////////////////
// Loaded during initial to intiliaze the socket
///////////////////////////////////////////////////////////////////////////////
static int uart_init_compiletf(char*user_data)
{
    return 0;
}


static int uart_init_calltf(char*user_data)
{
    vpi_printf("Load UART VPI, init the socket\n");

    // open the socket
    socketfd = socket(AF_INET, SOCK_STREAM, 0);
    if (socketfd==-1)
        error("ERROR: failed to open a TCP socket");

    flags = fcntl(socketfd, F_GETFL);
    if (flags==-1)
        error("ERROR: can't get flag on TCP socket");

    if (fcntl(socketfd, F_SETFL, flags | O_NONBLOCK)==-1)
        error("ERROR: couldn't set the socket as non-blocking");

    // initialize the buffer
    // bzero((char *) &serv_addr, sizeof(serv_addr));

    // setup the socket
    portno = 33334;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(portno);
    addr.sin_addr.s_addr = htonl(INADDR_ANY);

    if (bind(socketfd, (struct sockaddr *) &addr, sizeof(addr))==-1)
        error("ERROR on binding");

    if (listen(socketfd, 100)==-1) {
        error("Failed to listen");
    }
    vpi_printf("Socket is initialized\n");
    return 0;
}

///////////////////////////////////////////////////////////////////////////////
// Close gently the socket
///////////////////////////////////////////////////////////////////////////////
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

///////////////////////////////////////////////////////////////////////////////
// Listen to the socket to fetch data, non-blocking
///////////////////////////////////////////////////////////////////////////////
static int uart_listen_compiletf(char*user_data)
{
    return 0;
}

static int uart_listen_calltf(char*user_data)
{
    // vpi_printf("Listen the socket\n");

    int client_socket_fd = accept(socketfd, NULL, NULL);
    if (client_socket_fd == -1) {
        if (errno == EWOULDBLOCK) {
            vpi_printf("No pending connections; sleeping for one second.\n");
            sleep(1);
        } else {
            error("Error when accepting connection\n");
        }
    } else {

        bzero(buffer,256);
        int n = read(client_socket_fd, buffer, 255);
        if (n < 0) {
            vpi_printf("Nothing to read from socket\n");
        } else {
            vpi_printf("Here is the message: %s\n",buffer);
        }

        char msg[] = "hello\n";
        vpi_printf("Got a connection; writing 'hello' then closing.\n");
        send(client_socket_fd, msg, sizeof(msg), 0);
        // close(client_socket_fd);
        return 2;
    }
    return 0;
}


///////////////////////////////////////////////////////////////////////////////
// Send data thru the socket
///////////////////////////////////////////////////////////////////////////////
static int uart_send_compiletf(char*user_data)
{
    return 0;
}

static int uart_send_calltf(char* user_data)
{
    // vpi_printf("Send data to the socket\n");

    char msg[] = "hello\n";
    send(socketfd, msg, sizeof(msg), 0);
    return 0;
}

///////////////////////////////////////////////////////////////////////////////
// Declare and register the functions to load them thru the VPI
///////////////////////////////////////////////////////////////////////////////

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

    tf_data.type      = vpiSysFunc;
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

    tf_data.type      = vpiSysFunc;
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
    uart_send_register,
    uart_listen_register,
    uart_close_register,
    0
};
