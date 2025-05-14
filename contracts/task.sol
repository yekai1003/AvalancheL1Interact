// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
    角色分析：发布者、执行者
    功能分析：
        发布者：发布任务、确认任务
        执行者：接受任务、提交任务
        辅助 ： 查看数据
    结构设计：
        结构：任务id、发行方、接受方、描述、奖励、状态、时间戳、评价
    编码实现:

*/

interface IERC20 {

    function balanceOf(address _owner) external  view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external  returns (bool success);
    //function approve(address _spender, uint256 _value) external  returns (bool success);
    //function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    //event Transfer(address indexed _from, address indexed _to, uint256 _value);
    //event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// 任务结构
struct TaskInfo {
    address issuer;
    address worker;
    string  desc;
    uint256 bonus;
    uint8   status; // 0 - 未开始 1 - 已接受 2- 已提交 3 - 已确认
    string  comment;
    uint256 timestamp;
}

contract Task {
    TaskInfo[] tasks; //全部任务列表
    address token; // 定义token合约的地址
    // 定义状态常量
    uint8 constant TASK_BEGIN  = 0;
    uint8 constant TASK_TAKE   = 1;
    uint8 constant TASK_COMMIT = 2;
    uint8 constant TASK_CONFRIM= 3;
    // 注册固定送积分数量
    uint256 constant FAUCETS = 100;
    mapping (address=>bool) alreadyFaucets;

    event TaskIssue(address indexed _issuer, uint256 _bonus, string _desc);

    constructor(address _token) {
        token = _token;
    }

    // 发布任务
    function issue(string memory _desc, uint256 _bonus) public {
        require(_bonus > 0, "bonus <= 0");
        require(bytes(_desc).length > 0, "desc is null");
        // 余额要充足
        require(IERC20(token).balanceOf(msg.sender) >= _bonus, "user's balance not enough");
        TaskInfo memory task = TaskInfo(msg.sender, address(0), _desc, _bonus, TASK_BEGIN, "", block.timestamp);
        tasks.push(task);
        emit TaskIssue(msg.sender, _bonus, _desc);
    }
    // 接受任务
    function take(uint256 _index) public {
        require(_index < tasks.length, "index out of range");
        require(tasks[_index].status == TASK_BEGIN, "task's status invalid");
        require(tasks[_index].worker == address(0), "task's worker already exists");
        TaskInfo storage task = tasks[_index];
        task.worker = msg.sender;
        task.status = TASK_TAKE;
    }
    // 提交任务
    function commit(uint256 _index) public {
        require(_index < tasks.length, "index out of range");
        require(tasks[_index].status == TASK_TAKE, "task's status invalid");
        require(tasks[_index].worker == msg.sender, "only task's worker can do");
        TaskInfo storage task = tasks[_index];
        task.status = TASK_COMMIT;
    }
    // 确认任务
    function confirm(uint256 _index, string memory _comment, uint8 _status) public {
        require(_index < tasks.length, "index out of range");
        require(tasks[_index].status == TASK_COMMIT, "task's status invalid");
        require(tasks[_index].issuer == msg.sender, "only task's issuer can do");
        TaskInfo storage task = tasks[_index];
        task.comment = _comment;
        // 任务通过 _status = 3 & 任务不通过 other
        if(_status == TASK_CONFRIM) {
            // 任务通过
            task.status = TASK_CONFRIM;
            // 付款
            // issuer -> worker bonus 
            // IERC20(token).transfer(task.worker, task.bonus);  // 无效代码
            // w1 ->A(合约).a1(函数）-> B(合约).b1(函数） b1函数看到的msg.sender是A合约的地址
            IERC20(token).transferFrom(task.issuer, task.worker, task.bonus);
        } else {
            // 任务不通过
            task.status = TASK_TAKE;
        }
    }

    // 查看单一任务的信息
    function getOneTask(uint _index) public  view  returns (TaskInfo memory) {
        return tasks[_index];
    }
    // 查看所有任务的信息
    function getAllTasks() public  view  returns (TaskInfo[] memory) {
        return tasks;
    }

    // 注册送点token
    function register() public {
        // 从task合约转移给msg.sender
        require(!alreadyFaucets[msg.sender], "user already call faucets");
        alreadyFaucets[msg.sender] = true;
        IERC20(token).transfer(msg.sender, FAUCETS); 
    }
}
