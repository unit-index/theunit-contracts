# Farm 规则

1 用户可以拿出 ETH 或者 BTC 池子借 TINU 给用户。
用户用于 addLiquidity。并且把 LP Wrap 成 ULP，如果 TINU 是借来的，需要把 ULP 抵押给池子。
为什么要这么做？因为不能直接接受LP token。 这样需要给LP Token 喂价。避免用户自己去充LP抵押进来。

2 LP需要换成ULP才可以抵押到池子。ULP抵押的抵押不能算作资产再去借TINU。 用户也可以自己把LP换成ULP，这个不限制它。

3 持有 ULP 者才会有 Farm 奖励。

# API

Stake ETH, lockDay 有30天，90天，180天， 360天。 

```
 function depositETH(uint8 lock) public; 
```

_depositToken  为质押的token 
```
 function deposit(address _depositToken, uint256 _amount, uint8 _lockDay)
```