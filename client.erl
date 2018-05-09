-module(client).
-author("Joe Chasinga <jo.chasinga@gmail.com>").
-export([logon/2, logoff/2, init/2, ping/3, loop/2, send/3]).

%%--------------------------------------------------------------------
%% @doc  Connect client to the server by nodename
%% @end
%%--------------------------------------------------------------------
-spec logon(ServerNode::atom(), Name::string() | atom()) -> none().
logon(ServerNode, Name) ->
    spawn(?MODULE, init, [ServerNode, Name]).

%%--------------------------------------------------------------------
%% @doc  Disconnect the client from the server
%% @end
%%--------------------------------------------------------------------
-spec logoff(ServerNode::atom(), Name::string() | atom()) -> none().
logoff(ServerNode, Name) ->
    {server, ServerNode} ! {offline, Name}.

%%--------------------------------------------------------------------
%% @doc  Send an online message to server
%%       Usually not called directly
%% @end
%%--------------------------------------------------------------------
-spec init(ServerNode::atom(), Name::string() | atom()) -> none().
init(ServerNode, Name) ->
    {server, ServerNode} ! {online, Name, self()},
    loop(ServerNode, Name).

%%--------------------------------------------------------------------
%% @doc  Send a unique ping message a targeted user
%%       Used with '@UserName' pattern in the sent message
%% @end
%%--------------------------------------------------------------------
-spec ping(ServerNode::atom(), From::string() | atom(), 
	   To::string() | atom()) -> none().
ping(ServerNode, From, To) ->
    {server, ServerNode} ! {ping, From, To}.


%%--------------------------------------------------------------------
%% @doc  Send a text message to the server
%% @end
%%--------------------------------------------------------------------
-spec send(ServerNode::atom(), Msg::string(), 
	   From::string() | atom()) -> none().
send(ServerNode, Msg, From) ->
    Words = string:split(Msg, " ", all),
    TargetUsers = [tl(N) || N <- Words, hd(N) == $@],
    lists:foreach(fun(U) -> ping(ServerNode, From, U) end, TargetUsers),
    {server, ServerNode} ! {send, Msg, From}.

%%--------------------------------------------------------------------
%% @doc  Client loop
%% @end
%%--------------------------------------------------------------------
-spec loop(ServerNode::atom(), Name::string() | atom()) -> none().
loop(ServerNode, Name) ->
    receive
        {msg, Msg, From} ->
            io:format("~p said: ~p~n", [From, Msg]),
            loop(ServerNode, Name);
        {send_msg, Msg} ->
            {server, ServerNode} ! {send, Msg, Name},
            loop(ServerNode, Name);
        {online_nodes, OnlineNodes} ->
            io:format("Total ~p users are online~n", [length(OnlineNodes)]),
            loop(ServerNode, Name);
        {ping, From} ->
	    io:format("You get pinged by ~p~n", [From]),
	    loop(ServerNode, Name);
        go_offline ->
	    io:format("", []),
            {server, ServerNode} ! {offline, Name}
    end.

