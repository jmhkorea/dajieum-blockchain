// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DaJeumToken
 * @dev 다지음 작명회사의 플랫폼 토큰 컨트랙트
 */
contract DaJeumToken is ERC20, ERC20Burnable, Ownable {
    // 서비스 이용료 관련 이벤트
    event ServicePayment(address indexed user, uint256 amount, string serviceType);
    
    // 토큰 발행 이벤트
    event TokensMinted(address indexed to, uint256 amount);
    
    // 서비스 유형별 가격 매핑
    mapping(string => uint256) public servicePrices;
    
    /**
     * @dev 생성자
     * @param initialSupply 초기 발행량
     */
    constructor(uint256 initialSupply) ERC20("DaJeum Token", "DJM") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply * 10 ** decimals());
        
        // 기본 서비스 가격 설정
        servicePrices["naming"] = 100 * 10 ** decimals();        // 작명 서비스
        servicePrices["certificate"] = 50 * 10 ** decimals();    // 인증서 발행
        servicePrices["premium"] = 500 * 10 ** decimals();       // 프리미엄 서비스
    }
    
    /**
     * @dev 토큰 추가 발행 (관리자 전용)
     * @param to 수신자 주소
     * @param amount 발행량
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }
    
    /**
     * @dev 서비스 가격 설정 (관리자 전용)
     * @param serviceType 서비스 유형
     * @param price 가격
     */
    function setServicePrice(string memory serviceType, uint256 price) public onlyOwner {
        servicePrices[serviceType] = price;
    }
    
    /**
     * @dev 서비스 가격 조회
     * @param serviceType 서비스 유형
     * @return 서비스 가격
     */
    function getServicePrice(string memory serviceType) public view returns (uint256) {
        return servicePrices[serviceType];
    }
    
    /**
     * @dev 서비스 이용료 지불
     * @param serviceType 서비스 유형
     * @return 성공 여부
     */
    function payForService(string memory serviceType) public returns (bool) {
        uint256 price = servicePrices[serviceType];
        require(price > 0, "Service type not found");
        require(balanceOf(msg.sender) >= price, "Insufficient balance");
        
        // 토큰 전송 (사용자 -> 컨트랙트 소유자)
        _transfer(msg.sender, owner(), price);
        
        // 이벤트 발생
        emit ServicePayment(msg.sender, price, serviceType);
        
        return true;
    }
    
    /**
     * @dev 특정 금액의 서비스 이용료 지불
     * @param amount 금액
     * @param serviceType 서비스 유형
     * @return 성공 여부
     */
    function payCustomAmount(uint256 amount, string memory serviceType) public returns (bool) {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // 토큰 전송 (사용자 -> 컨트랙트 소유자)
        _transfer(msg.sender, owner(), amount);
        
        // 이벤트 발생
        emit ServicePayment(msg.sender, amount, serviceType);
        
        return true;
    }
    
    /**
     * @dev 여러 계정에 토큰 배포 (관리자 전용)
     * @param recipients 수신자 주소 배열
     * @param amounts 금액 배열
     * @return 성공 여부
     */
    function distributeTokens(address[] memory recipients, uint256[] memory amounts) public onlyOwner returns (bool) {
        require(recipients.length == amounts.length, "Array length mismatch");
        
        for (uint i = 0; i < recipients.length; i++) {
            require(recipients[i] != address(0), "Invalid recipient address");
            _transfer(msg.sender, recipients[i], amounts[i]);
            emit TokensMinted(recipients[i], amounts[i]);
        }
        
        return true;
    }
    
    /**
     * @dev 토큰 소각 (사용자가 직접 호출)
     * @param amount 소각할 금액
     */
    function burnTokens(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        _burn(msg.sender, amount);
    }
}
