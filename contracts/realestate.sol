pragma solidity  ^0.8.0;

//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1400  {
 /************************************* Token description ****************************************/
  string internal _name;
  string internal _symbol;
  uint256 internal _totalSupply;
  bool internal _migrated;
  address internal _controller;
  address internal _operator;
  uint256[] internal _defaultPartitions;

mapping(address => uint256) internal _balances;
  /*********************************** Partitions  mappings ***************************************/
  // List of partitions.
  uint256[] internal _totalPartitions;

  // Mapping from partition to their index.
  mapping (uint256 => uint256) internal _indexOfTotalPartitions;

  // Mapping from partition to global balance of corresponding partition.
  mapping (uint256 => uint256) internal _totalSupplyByPartition;

  // Mapping from tokenHolder to their partitions.
  mapping (address => uint256[]) internal _partitionsOf;

  // Mapping from (tokenHolder, partition) to their index.
  mapping (address => mapping (uint256 => uint256)) internal _indexOfPartitionsOf;

  // Mapping from (tokenHolder, partition) to balance of corresponding partition.
  mapping (address => mapping (uint256 => uint256)) internal _balanceOfByPartition;
  /************************************************************************************************/

    constructor(
    string memory tokenName, string memory tokenSymbol, address initialControllers) {
    _name = tokenName;
    _symbol = tokenSymbol;
    _totalSupply = 0;
    _controller = initialControllers;
    _operator = initialControllers; // 초기 오퍼레이터는 컨트롤러로 지정함
  }
/************************************************************************************************/
  /****************************** EXTERNAL FUNCTIONS (ERC20 INTERFACE) ****************************/
  /************************************************************************************************/


  // /**
  //  * @dev Get the total number of issued tokens.
  //  * @return Total supply of tokens currently in circulation.
  //  */
   function totalSupply() external view returns (uint256) {return _totalSupply;}

  // function balanceOf(address tokenHolder) external view returns (uint256) { return _balances[tokenHolder];}
 
  // function transfer(address to, uint256 value) external override returns (bool) {return true;}

  // function allowance(address owner, address spender) external override view returns (uint256) {}
  
  // function approve(address spender, uint256 value) external override returns (bool) {}
 
  // function transferFrom(address from, address to, uint256 value) external override returns (bool) {}
  // // ******************* Token Information ********************
   function balanceOfByPartition(uint256 partition, address tokenHolder) public view returns (uint256){return _balanceOfByPartition[tokenHolder][partition];}
   function partitionsOf(address tokenHolder) public view returns (uint256[] memory){ return _partitionsOf[tokenHolder];}

  // *********************** Transfers ************************
 // function transferWithData(address to, uint256 value, bytes calldata data) external{}
 // function transferFromWithData(address from, address to, uint256 value, bytes calldata data) external{}

  // *************** Partition Token Transfers ****************
   function transferByPartition(uint256 fromPartition,address from,address to,uint256 value) internal {

    uint256 toPartition = fromPartition;
    removeTokenFromPartition(from, fromPartition, value);
    if( fromPartition == 1 ){
        transferWithData(from, to, value);
    }
    addTokenToPartition(to, toPartition, value);
  }
  
  function transferWithData(address from,address to,uint256 value) internal{
    
    _balances[from] -= value;
    _balances[to] += value;
  }

  //function operatortransferByPartition(uint256 partition, address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external returns (bytes32){}
  //function allowanceByPartition(uint256 partition, address owner, address spender) external view returns (uint256){}

  function addTokenToPartition(address to, uint256 partition, uint256 value) internal {
    if(value != 0) {
      if (_indexOfPartitionsOf[to][partition] == 0) {
        _partitionsOf[to].push(partition);
        _indexOfPartitionsOf[to][partition] = _partitionsOf[to].length;
      }
      _balanceOfByPartition[to][partition] += value;

      if (_indexOfTotalPartitions[partition] == 0) {
        _totalPartitions.push(partition);
        _indexOfTotalPartitions[partition] = _totalPartitions.length;
      }
      _totalSupplyByPartition[partition] += value;
    }
  }

  function removeTokenFromPartition(address from, uint256 partition, uint256 value) internal {
    _balanceOfByPartition[from][partition] -= value;
    _totalSupplyByPartition[partition] -= value;
  }
  // ****************** Controller Operation ******************
 // function isControllable() external view returns (bool){}
  // function controllerTransfer(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // removed because same action can be achieved with "operatortransferByPartition"
  // function controllerRedeem(address tokenHolder, uint256 value, bytes calldata data, bytes calldata operatorData) external; // removed because same action can be achieved with "operatorRedeemByPartition"

  // ****************** Operator Management *******************
  //function authorizeOperator(address operator) external{}
  //function revokeOperator(address operator) external{}
  //function authorizeOperatorByPartition(uint256 partition, address operator) external{}
  //function revokeOperatorByPartition(uint256 partition, address operator) external{}

  // ****************** Operator Information ******************
  //function isOperator(address operator, address tokenHolder) external view returns (bool){}
  //function isOperatorForPartition(uint256 partition, address operator, address tokenHolder) external view returns (bool){}

  // ********************* Token Issuance *********************
  //function isIssuable() external view returns (bool){}
  
  function issue(address tokenHolder, uint256 value)
    internal virtual
  {
    
    _totalSupply += value;
    _balances[tokenHolder] += value;
    addTokenToPartition(tokenHolder, 1, value); //파티션 1 토큰 발행
    addTokenToPartition(tokenHolder, 2, value); //파티션 2 토큰 발행
  }

  //function issueByPartition(uint256 partition, address tokenHolder, uint256 value, bytes calldata data) external{}

  // ******************** Token Redemption ********************
  //function redeem(uint256 value, bytes calldata data) external{}
  //function redeemFrom(address tokenHolder, uint256 value, bytes calldata data) external{}
 // function redeemByPartition(uint256 partition, uint256 value, bytes calldata data) external{}
  //function operatorRedeemByPartition(uint256 partition, address tokenHolder, uint256 value, bytes calldata operatorData) external{}
}
 

/////////////////////////////////////////////////////////////////////////////////
contract RealEstateToken is ERC1400("IPtoken","IP",msg.sender){
    struct Contribution {
        uint256 visits;
        uint256 duration;
        uint256 payments;
        uint256 referrals;
    }
    
    struct Rental {
        address tenant;
        string startTime;
        string endTime;
    }

    mapping(address => Contribution) public contributions;
    mapping(address => Rental) public rentals; //renter -{tenant, startTime, endTime}
    address[] public renter_list;
    address[] public tmp_list;
    
    
    constructor() {
        super.issue(msg.sender, 100);
    }
    // 토큰 소유자의 기여행위
    function addContributionbyTenant(uint256 visits, uint256 duration, uint256 payments, uint256 referrals) public {
        Contribution storage contribution = contributions[msg.sender];
        contribution.visits += visits;
        contribution.duration += duration;
        contribution.payments += payments;
        contribution.referrals += referrals;
        
    }
    function getContribution() public view returns (uint256, uint256, uint256, uint256){
      address addr;
      if(_balanceOfByPartition[msg.sender][1] > 0){
        addr = msg.sender;
      }else if(_balanceOfByPartition[msg.sender][1] == 0){
        addr = rentals[msg.sender].tenant;
      }
      Contribution storage contribution = contributions[addr];
      return (contribution.visits, contribution.duration, contribution.payments, contribution.referrals);
    }
    //토크 대여자의 기여행위
    function addContributionbyRenter(uint256 visits, uint256 duration, uint256 payments,uint256 referrals) public {
        address tenant = rentals[msg.sender].tenant;
        Contribution storage contribution = contributions[tenant];
        contribution.visits += visits;
        contribution.duration += duration;
        contribution.payments += payments;
        contribution.referrals += referrals;
        
    }

    //토큰 소유자가 토큰 대여해주는 함수.
    function rentToken(address renter , string memory startTime, string memory endTime) public {
        rentals[renter] = Rental({
            tenant: msg.sender,
            startTime: startTime,
            endTime: endTime
        });
        super.transferByPartition(2, msg.sender, renter, 1);
        renter_list.push(renter);
    }
    // 렌트한 토큰 반환하는 함수 call by operator/controller
    function returnRentToken(address renter) public {
        rentals[renter] = Rental({tenant:address(0),startTime:'null',endTime:'null'});
        super.transferByPartition(2, renter, msg.sender, 1);
        uint256 index = 0;
        for(uint256 i=0; i<renter_list.length;i++){
            if(renter_list[i] == renter){
                index = i;
                break;
            }
        }
        delete renter_list[index];
    }
    // 렌트한 토큰 반환하는 함수 call by renter
    function returnRentTokenbyRenter(address tenant) public {
        rentals[msg.sender] = Rental({tenant:address(0),startTime:'null',endTime:'null'});
        super.transferByPartition(2, msg.sender, tenant, 1);
    }

    // 새로운 토큰 소유자에게로 기여 정보 변경
    function changeRentInfo(address new_tenant) public{
         for (uint256 i=0; i<renter_list.length; i++) {
            if (rentals[renter_list[i]].tenant == msg.sender) {
                rentals[renter_list[i]].tenant = new_tenant; 
                break;
            }
        }
    }
    // 렌탈정보 출력
    function getRentInfobyRenter(address renter) public view returns(address, string memory , string memory) {
        Rental memory rental = rentals[renter];
        return (rental.tenant, rental.startTime, rental.endTime);
    }

    function getRenterList() public view returns(address[] memory){
      return renter_list;
    }  
    
    function calculateRewards(address tenant) public view returns(uint256, uint256, uint256) {
        uint256 BASE_REWARD = 1;
        uint256 REWARD_FACTOR = 5;
        uint256 totalContribution = contributions[tenant].visits + contributions[tenant].duration + 
            contributions[tenant].payments + contributions[tenant].referrals;
        uint256 performanceReward = totalContribution / REWARD_FACTOR;
        uint256 baseReward = BASE_REWARD;
        uint256 reward = baseReward + performanceReward;
        return (reward, baseReward, performanceReward);
    }
    
    function claimRewards(address tenant) public returns(address, uint256) {
        uint256 reward;
        uint256 performanceReward;
        uint256 baseReward;
        (reward, performanceReward, baseReward) = calculateRewards(tenant);
        require(reward > 0, "No rewards to claim");
        contributions[tenant] = Contribution(0, 0, 0, 0);
        //기본보상 +  성과보상 에 해당하는 리워드 토큰 발행
        super.issue(msg.sender, reward);
        return (tenant, reward);
    }


    function transferPartition1Ownership(address new_tenant) public {
        require(_balanceOfByPartition[msg.sender][1] > 0, "No partition1 token to sell");
        //partition 1 token 전달
        super.transferByPartition(1, msg.sender, new_tenant, 1);

        //partition 2 token 전달
        if(_balanceOfByPartition[msg.sender][2] > 0){
            super.transferByPartition(2, msg.sender, new_tenant, 1);
        //partition 2 token 모두 대여해줘서 없는 경우 대여정보 수정
        }else if(_balanceOfByPartition[msg.sender][2] == 0){
        //대여해준지 가장 오래된 partition 2 의 소유자를 변경함
            changeRentInfo(new_tenant);
           
        }
    }    
}