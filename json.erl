-module (json).
-export ([decode/1]).

%%json格式跟erlang格式对应关系
%%{a:b}->[{a,b}]
%%{a:[a,b,c]}->[{a,[a,b,c]}]
%%{a:333,b:23} -> [{a,333},{b,23}]
%%{a:[true,false,null,undefined]} -> [{a,[true,false,undefined,undefined]}]

decode(BinData) ->
	Bin2 = re:replace(BinData, "\s+", "", [{return, binary}, global]),
    {DataList, _Bin3} = read_token_object(Bin2),
    DataList.


%%从二进制中读取一个json对象
read_token_object(Bin) ->
    read_token_object(Bin, []).
read_token_object(<<A,Bin2/binary>>=Bin, DataStack) ->
    case A of
        ${ ->
            <<$", Bin3/binary>> = Bin2,
            {Key, Bin4} = read_token_string(Bin3),
            <<$:, Bin5/binary>> = Bin4,
            {Value, Bin6} = read_token_object(Bin5),
            read_token_object(Bin6, [{Key, Value} |DataStack]);
        $} ->
            {lists:reverse(DataStack), Bin2};
        $" ->
            read_token_string(Bin2);
        $[ ->
            read_token_array(Bin2);
        $, ->
            {Key, Bin3} = read_token_string(Bin2),
            {Value, Bin4} = read_token_object(Bin3),
            read_token_object(Bin4, [{Key, Value}|DataStack]);
        $n ->
            <<"null", Bin3/binary>> = Bin2,
            {null, Bin3};
        $f ->
            <<"false", Bin3/binary>> = Bin2,
            {false, Bin3};
        $t ->
            <<"true", Bin3/binary>> = Bin2,
            {true, Bin3};
        _ when $0 =< A andalso A =< $9 ->
            read_token_number(Bin)
    end.
%%读取一个数组结构
read_token_array(Bin) ->
    read_token_array([], Bin).
read_token_array(Array, <<A,Bin2/binary>>=Bin) ->
    case A of
        $" ->
            {String, Bin3} = read_token_string(Bin2),
            read_token_array([String|Array], Bin3);
        $, ->
            read_token_array(Array, Bin2);
        $f ->
            <<"false", Bin3/binary>> = Bin,
            read_token_array([false|Array], Bin3);
        $t ->
            <<"true", Bin3/binary>> = Bin,
            read_token_array([true|Array], Bin3);
        $n ->
            <<"null", Bin3/binary>> = Bin,
            read_token_array([undefined|Array], Bin3);
        $u ->
            <<"undefined", Bin3/binary>> = Bin,
            read_token_array([undefined|Array], Bin3);
        ${ ->
            {Data, Bin3} = read_token_object(Bin),
            read_token_array([Data|Array], Bin3);
        _ when A =< $9 andalso $0 =< A ->
            {Number, Bin3} = read_token_number(Bin),
            read_token_array([Number|Array], Bin3);
        $] ->
            {lists:reverse(Array), Bin2}
    end.
%%读取一个字符串结构
read_token_string(Bin) ->
    read_token_string(<<>>, Bin).
read_token_string(Bin1, <<A,Bin3/binary>>) ->
    case A of
        $" ->
            {Bin1, Bin3};
        _ ->
            read_token_string(<<Bin1/binary,A>>, Bin3)
    end.

%%读取一个数字
read_token_number(Bin) ->
    read_token_number(<<>>, Bin, false).
read_token_number(Bin2, <<A,Bin3/binary>>=Bin, IsFloat) ->
    case A of
        $. ->
            read_token_number(<<Bin2/binary, A>>, Bin3, true);
        _ when  $0 =< A andalso A =< $9 ->
            read_token_number(<<Bin2/binary, A>>, Bin3, IsFloat);
        _ when IsFloat->
            Number = erlang:binary_to_float(Bin2),
            {Number, Bin};
        _ ->
            Number = erlang:binary_to_integer(Bin2),
            {Number, Bin}
    end.
