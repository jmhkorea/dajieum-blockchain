// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title DaJeumNaming
 * @dev 다지음 작명회사의 한글 이름 데이터를 블록체인에 저장하는 스마트컨트랙트
 */
contract DaJeumNaming is Ownable {
    using Counters for Counters.Counter;
    
    // 이름 ID 카운터
    Counters.Counter private _nameIds;
    
    // 이름 데이터 구조체
    struct NameData {
        string fullName;       // 성+이름 (한글)
        uint birthYear;        // 출생년도
        uint birthMonth;       // 출생월
        uint birthDay;         // 출생일
        string gender;         // 성별
        uint256 timestamp;     // 등록 시간
        address registrar;     // 등록자 주소
    }
    
    // 이름 데이터 저장소 (키: 고유 ID, 값: 이름 데이터)
    mapping(uint256 => NameData) public names;
    
    // 이름별 인덱스 (키: 이름 해시, 값: 고유 ID)
    mapping(bytes32 => uint256) public nameIndices;
    
    // 이름 등록 이벤트
    event NameRegistered(uint256 indexed id, string fullName, uint birthYear, uint birthMonth, uint birthDay, string gender);
    
    // 이름 조회 이벤트
    event NameSearched(uint256 indexed id, address searcher);
    
    // 배치 등록 이벤트
    event BatchNamesRegistered(uint256 startId, uint256 endId, uint256 count);
    
    /**
     * @dev 생성자
     */
    constructor() Ownable(msg.sender) {}
    
    /**
     * @dev 이름 등록 함수
     * @param _fullName 성+이름 (한글)
     * @param _birthYear 출생년도
     * @param _birthMonth 출생월
     * @param _birthDay 출생일
     * @param _gender 성별
     * @return 등록된 이름의 ID
     */
    function registerName(
        string memory _fullName,
        uint _birthYear,
        uint _birthMonth,
        uint _birthDay,
        string memory _gender
    ) public returns (uint256) {
        // 이름 중복 체크
        bytes32 nameHash = keccak256(abi.encodePacked(_fullName, _birthYear, _birthMonth, _birthDay));
        require(nameIndices[nameHash] == 0, "Name already registered");
        
        // 기본 유효성 검사
        require(bytes(_fullName).length > 0, "Name cannot be empty");
        require(_birthYear > 1900 && _birthYear <= 2100, "Invalid birth year");
        require(_birthMonth >= 1 && _birthMonth <= 12, "Invalid birth month");
        require(_birthDay >= 1 && _birthDay <= 31, "Invalid birth day");
        
        // ID 증가
        _nameIds.increment();
        uint256 newNameId = _nameIds.current();
        
        // 이름 데이터 저장
        names[newNameId] = NameData({
            fullName: _fullName,
            birthYear: _birthYear,
            birthMonth: _birthMonth,
            birthDay: _birthDay,
            gender: _gender,
            timestamp: block.timestamp,
            registrar: msg.sender
        });
        
        // 이름 인덱스 저장
        nameIndices[nameHash] = newNameId;
        
        // 이벤트 발생
        emit NameRegistered(newNameId, _fullName, _birthYear, _birthMonth, _birthDay, _gender);
        
        return newNameId;
    }
    
    /**
     * @dev 배치 이름 등록 함수 (관리자 전용)
     * @param _fullNames 성+이름 배열
     * @param _birthYears 출생년도 배열
     * @param _birthMonths 출생월 배열
     * @param _birthDays 출생일 배열
     * @param _genders 성별 배열
     * @return 등록된 이름의 시작 ID와 끝 ID
     */
    function batchRegisterNames(
        string[] memory _fullNames,
        uint[] memory _birthYears,
        uint[] memory _birthMonths,
        uint[] memory _birthDays,
        string[] memory _genders
    ) public onlyOwner returns (uint256, uint256) {
        // 배열 길이 검증
        require(_fullNames.length > 0, "Empty batch");
        require(
            _fullNames.length == _birthYears.length &&
            _fullNames.length == _birthMonths.length &&
            _fullNames.length == _birthDays.length &&
            _fullNames.length == _genders.length,
            "Array length mismatch"
        );
        
        uint256 startId = _nameIds.current() + 1;
        uint256 count = 0;
        
        // 배치 등록
        for (uint i = 0; i < _fullNames.length; i++) {
            // 이름 중복 체크
            bytes32 nameHash = keccak256(abi.encodePacked(_fullNames[i], _birthYears[i], _birthMonths[i], _birthDays[i]));
            if (nameIndices[nameHash] != 0) {
                continue; // 중복된 이름은 건너뜀
            }
            
            // 기본 유효성 검사
            if (
                bytes(_fullNames[i]).length == 0 ||
                _birthYears[i] <= 1900 || _birthYears[i] > 2100 ||
                _birthMonths[i] < 1 || _birthMonths[i] > 12 ||
                _birthDays[i] < 1 || _birthDays[i] > 31
            ) {
                continue; // 유효하지 않은 데이터는 건너뜀
            }
            
            // ID 증가
            _nameIds.increment();
            uint256 newNameId = _nameIds.current();
            
            // 이름 데이터 저장
            names[newNameId] = NameData({
                fullName: _fullNames[i],
                birthYear: _birthYears[i],
                birthMonth: _birthMonths[i],
                birthDay: _birthDays[i],
                gender: _genders[i],
                timestamp: block.timestamp,
                registrar: msg.sender
            });
            
            // 이름 인덱스 저장
            nameIndices[nameHash] = newNameId;
            
            // 개별 이벤트 발생
            emit NameRegistered(newNameId, _fullNames[i], _birthYears[i], _birthMonths[i], _birthDays[i], _genders[i]);
            
            count++;
        }
        
        uint256 endId = _nameIds.current();
        
        // 배치 등록 이벤트 발생
        emit BatchNamesRegistered(startId, endId, count);
        
        return (startId, endId);
    }
    
    /**
     * @dev 최적화된 배치 이름 등록 함수 (가스비 절감, 관리자 전용)
     * @param _nameDataHashes 이름 데이터 해시 배열 (fullName, birthYear, birthMonth, birthDay, gender를 ABI 인코딩하여 해시)
     * @return 등록된 이름의 시작 ID와 끝 ID
     */
    function batchRegisterNamesOptimized(
        bytes[] memory _nameDataHashes
    ) public onlyOwner returns (uint256, uint256) {
        require(_nameDataHashes.length > 0, "Empty batch");
        
        uint256 startId = _nameIds.current() + 1;
        uint256 count = 0;
        
        // 배치 등록
        for (uint i = 0; i < _nameDataHashes.length; i++) {
            // 데이터 디코딩
            (
                string memory fullName,
                uint birthYear,
                uint birthMonth,
                uint birthDay,
                string memory gender
            ) = abi.decode(_nameDataHashes[i], (string, uint, uint, uint, string));
            
            // 이름 중복 체크
            bytes32 nameHash = keccak256(abi.encodePacked(fullName, birthYear, birthMonth, birthDay));
            if (nameIndices[nameHash] != 0) {
                continue; // 중복된 이름은 건너뜀
            }
            
            // 기본 유효성 검사
            if (
                bytes(fullName).length == 0 ||
                birthYear <= 1900 || birthYear > 2100 ||
                birthMonth < 1 || birthMonth > 12 ||
                birthDay < 1 || birthDay > 31
            ) {
                continue; // 유효하지 않은 데이터는 건너뜀
            }
            
            // ID 증가
            _nameIds.increment();
            uint256 newNameId = _nameIds.current();
            
            // 이름 데이터 저장
            names[newNameId] = NameData({
                fullName: fullName,
                birthYear: birthYear,
                birthMonth: birthMonth,
                birthDay: birthDay,
                gender: gender,
                timestamp: block.timestamp,
                registrar: msg.sender
            });
            
            // 이름 인덱스 저장
            nameIndices[nameHash] = newNameId;
            
            // 개별 이벤트 발생 (가스비 절감을 위해 배치 등록에서는 개별 이벤트 생략 가능)
            // emit NameRegistered(newNameId, fullName, birthYear, birthMonth, birthDay, gender);
            
            count++;
        }
        
        uint256 endId = _nameIds.current();
        
        // 배치 등록 이벤트 발생
        emit BatchNamesRegistered(startId, endId, count);
        
        return (startId, endId);
    }
    
    /**
     * @dev ID로 이름 데이터 조회
     * @param _id 이름 ID
     * @return 이름 데이터
     */
    function getNameById(uint256 _id) public returns (NameData memory) {
        require(_id > 0 && _id <= _nameIds.current(), "Invalid ID");
        
        emit NameSearched(_id, msg.sender);
        return names[_id];
    }
    
    /**
     * @dev 이름으로 검색
     * @param _fullName 성+이름
     * @param _birthYear 출생년도
     * @param _birthMonth 출생월
     * @param _birthDay 출생일
     * @return 이름 ID
     */
    function searchByName(
        string memory _fullName,
        uint _birthYear,
        uint _birthMonth,
        uint _birthDay
    ) public returns (uint256) {
        bytes32 nameHash = keccak256(abi.encodePacked(_fullName, _birthYear, _birthMonth, _birthDay));
        uint256 id = nameIndices[nameHash];
        require(id != 0, "Name not found");
        
        emit NameSearched(id, msg.sender);
        return id;
    }
    
    /**
     * @dev 총 등록된 이름 수 조회
     * @return 총 이름 수
     */
    function getTotalNames() public view returns (uint256) {
        return _nameIds.current();
    }
    
    /**
     * @dev 이름 등록 여부 확인
     * @param _fullName 성+이름
     * @param _birthYear 출생년도
     * @param _birthMonth 출생월
     * @param _birthDay 출생일
     * @return 등록 여부
     */
    function isNameRegistered(
        string memory _fullName,
        uint _birthYear,
        uint _birthMonth,
        uint _birthDay
    ) public view returns (bool) {
        bytes32 nameHash = keccak256(abi.encodePacked(_fullName, _birthYear, _birthMonth, _birthDay));
        return nameIndices[nameHash] != 0;
    }
}
