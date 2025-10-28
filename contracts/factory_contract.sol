// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./DataStorage.sol";
import "./issuance_of_documents.sol";
import "./DocumentNFT.sol";
import "./student_score.sol";
import "./voting_contract.sol";

/**
 * @title FactoryContract
 * @dev Factory pattern để deploy và quản lý tất cả các contract trong hệ thống
 */
contract FactoryContract {
    DataStorage public dataStorage;
    IssuanceOfDocument public issuanceContract;
    DocumentNFT public documentNFT;

    address[] public studentScoreContracts;
    mapping(address => bool) public isStudentScoreContract;
    
    address[] public votingContracts;
    mapping(address => bool) public isVotingContract;

    event DataStorageDeployed(address indexed dataStorageAddress);
    event IssuanceContractDeployed(address indexed issuanceAddress);
    event DocumentNFTDeployed(address indexed documentNFTAddress);
    event StudentScoreDeployed(address indexed scoreAddress);
    event VotingContractDeployed(address indexed votingAddress);
    event ContractAuthorized(address indexed contractAddress);

    address public deployer;

    constructor() {
        deployer = msg.sender;
        
        // Deploy DataStorage với owner tạm thời là FactoryContract (address(this))
        // để có thể authorize các contracts trong constructor
        dataStorage = new DataStorage(address(this));
        emit DataStorageDeployed(address(dataStorage));
        
        // Deploy IssuanceOfDocument
        issuanceContract = new IssuanceOfDocument(address(dataStorage));
        dataStorage.authorizeContract(address(issuanceContract));
        emit IssuanceContractDeployed(address(issuanceContract));
        emit ContractAuthorized(address(issuanceContract));
        
        // Deploy DocumentNFT với owner ban đầu là FactoryContract
        documentNFT = new DocumentNFT(address(dataStorage), address(this));
        dataStorage.authorizeContract(address(documentNFT));
        emit DocumentNFTDeployed(address(documentNFT));
        emit ContractAuthorized(address(documentNFT));
        
        // Transfer ownership của DocumentNFT cho IssuanceContract để nó có thể mint NFT
        documentNFT.transferOwnership(address(issuanceContract));
        
        // Set DocumentNFT address vào IssuanceContract
        issuanceContract.setDocumentNFT(address(documentNFT));
        
        // Transfer ownership của DataStorage cho deployer (user từ private key)
        // Bây giờ deployer có full control của DataStorage
        dataStorage.changeOwner(msg.sender);
    }

    modifier onlyDeployer() {
        require(
            msg.sender == deployer || msg.sender == dataStorage.owner(),
            "Only deployer or DataStorage owner can call this"
        );
        _;
    }

    function authorizeContract(address _contract) external onlyDeployer {
        dataStorage.authorizeContract(_contract);
        emit ContractAuthorized(_contract);
    }

    function deployStudentScore() external onlyDeployer returns (address) {
        StudentViolation studentScore = new StudentViolation(address(dataStorage));
        address scoreAddress = address(studentScore);
        
        dataStorage.authorizeContract(scoreAddress);
        
        studentScoreContracts.push(scoreAddress);
        isStudentScoreContract[scoreAddress] = true;
        
        emit StudentScoreDeployed(scoreAddress);
        emit ContractAuthorized(scoreAddress);
        
        return scoreAddress;
    }

    function deployVotingContract() external onlyDeployer returns (address) {
        VotingContract votingContract = new VotingContract(address(dataStorage));
        address votingAddress = address(votingContract);
        
        dataStorage.authorizeContract(votingAddress);
        
        votingContracts.push(votingAddress);
        isVotingContract[votingAddress] = true;
        
        emit VotingContractDeployed(votingAddress);
        emit ContractAuthorized(votingAddress);
        
        return votingAddress;
    }

    function getDataStorageAddress() external view returns (address) {
        return address(dataStorage);
    }

    function getIssuanceContractAddress() external view returns (address) {
        return address(issuanceContract);
    }

    function getDocumentNFTAddress() external view returns (address) {
        return address(documentNFT);
    }

    function getAllStudentScoreContracts() external view returns (address[] memory) {
        return studentScoreContracts;
    }

    function getAllVotingContracts() external view returns (address[] memory) {
        return votingContracts;
    }

    function getStudentScoreContractCount() external view returns (uint256) {
        return studentScoreContracts.length;
    }

    function getVotingContractCount() external view returns (uint256) {
        return votingContracts.length;
    }

    function isManager(address _manager) external view returns (bool) {
        return dataStorage.isManager(_manager);
    }

    function getStudentId(address _address) external view returns (uint256) {
        return dataStorage.getStudentIdByAddress(_address);
    }

    function isActiveStudent(address _address) external view returns (bool) {
        return dataStorage.isActiveStudent(_address);
    }

    function getSystemInfo() external view returns (
        address dataStorageAddr,
        address issuanceAddr,
        address documentNFTAddr,
        uint256 totalStudents,
        uint256 totalSigners,
        uint256 scoreContractCount,
        uint256 votingContractCount
    ) {
        return (
            address(dataStorage),
            address(issuanceContract),
            address(documentNFT),
            dataStorage.getTotalStudents(),
            dataStorage.getManagerCount(),
            studentScoreContracts.length,
            votingContracts.length
        );
    }
}