// SPDX-License-Identifier: MIT
pragma solidity^0.8.11;

import "./IERC20.sol";

contract Token is IERC20 {
    string tokenName; // 名称
    string tokenSym;  // 符号
    uint8  tokenDecimals = 6; // 精度
    uint256 tokenSupply; // 总发行量
    // 定义账户余额
    mapping (address => uint256) balances; // 用户余额表
    // 定义授权数据
    mapping (address=> mapping (address=>uint256)) allows; // 授权额度表
    constructor(string memory _name, string memory _sym, uint256 _supply) {
        tokenName = _name;
        tokenSym  = _sym;
        tokenSupply = _supply;
        balances[msg.sender] = _supply * 10 ** tokenDecimals;
    }
    function name() override  external  view returns (string memory) {
        return tokenName;
    }
    function symbol() override  external  view returns (string memory) {
        return  tokenSym;
    }
    function decimals() override external  view returns (uint8) {
        return tokenDecimals;
    }
    function totalSupply() override external  view returns (uint256) {
        return tokenSupply;
    }
    function balanceOf(address _owner) override external  view returns (uint256 balance) {
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) override external returns (bool success){
        require(_value > 0, "approve amount invalid");
        require(_to != address(0), "_spender is invalid");
        require(balances[msg.sender] >= _value, "user's balance not enough");
        balances[msg.sender] -= _value; // SafeMath
        balances[_to]        += _value; 
        
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    function transferFrom(address _from, address _to, uint256 _value) override external  returns (bool success){
        require(_value > 0, "approve amount invalid");
        require(_to != address(0), "_to is invalid");
        require(balances[_from] >= _value, "user's balance not enough");
        require(allows[_from][msg.sender] >= _value, "user's approve not enough");

        balances[_from] -= _value; // SafeMath
        balances[_to]   += _value; 
        allows[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    function approve(address _spender, uint256 _value) override external  returns (bool success) {
        // 授权给另外第三方，可以协助转账transferFrom ，_from 授权给了msg.sender
        // require(_value > 0, "approve amount invalid");
        require(_spender != address(0), "_spender is invalid");
        allows[msg.sender][_spender] = _value;

        emit  Approval(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) override external view returns (uint256 remaining) {
        return allows[_owner][_spender];
    }
   
}
