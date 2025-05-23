// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title DaJeumNFT
 * @dev 다지음 작명 인증서 NFT 컨트랙트
 */
contract DaJeumNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    
    // NFT ID 카운터
    Counters.Counter private _tokenIds;
    
    // 이름 ID와 NFT ID 매핑
    mapping(uint256 => uint256) public nameToToken;
    mapping(uint256 => uint256) public tokenToName;
    
    // NFT 메타데이터 구조체
    struct NFTMetadata {
        uint256 nameId;     // 이름 데이터 ID
        string imageURI;    // 인증서 이미지 URI
        uint256 timestamp;  // 발행 시간
    }
    
    // NFT ID별 메타데이터
    mapping(uint256 => NFTMetadata) public nftMetadata;
    
    // 다지음 이름 컨트랙트 주소
    address public namingContractAddress;
    
    // 이벤트
    event CertificateMinted(uint256 indexed tokenId, uint256 indexed nameId, address owner);
    event BatchCertificatesMinted(uint256 startTokenId, uint256 endTokenId, uint256 count);
    
    /**
     * @dev 생성자
     * @param _namingContractAddress 다지음 이름 컨트랙트 주소
     */
    constructor(address _namingContractAddress) ERC721("DaJeum Naming Certificate", "DJC") Ownable(msg.sender) {
        namingContractAddress = _namingContractAddress;
    }
    
    /**
     * @dev 이름 컨트랙트 주소 업데이트 (관리자 전용)
     * @param _newAddress 새 컨트랙트 주소
     */
    function updateNamingContractAddress(address _newAddress) public onlyOwner {
        require(_newAddress != address(0), "Invalid address");
        namingContractAddress = _newAddress;
    }
    
    /**
     * @dev NFT 인증서 발행
     * @param _to 소유자 주소
     * @param _nameId 이름 ID
     * @param _tokenURI 토큰 URI (메타데이터 JSON 경로)
     * @param _imageURI 인증서 이미지 URI
     * @return 발행된 토큰 ID
     */
    function mintCertificate(
        address _to,
        uint256 _nameId,
        string memory _tokenURI,
        string memory _imageURI
    ) public onlyOwner returns (uint256) {
        require(_to != address(0), "Invalid address");
        require(nameToToken[_nameId] == 0, "Certificate already minted for this name");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        // NFT 발행
        _mint(_to, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        
        // 메타데이터 저장
        nftMetadata[newTokenId] = NFTMetadata({
            nameId: _nameId,
            imageURI: _imageURI,
            timestamp: block.timestamp
        });
        
        // 매핑 저장
        nameToToken[_nameId] = newTokenId;
        tokenToName[newTokenId] = _nameId;
        
        // 이벤트 발생
        emit CertificateMinted(newTokenId, _nameId, _to);
        
        return newTokenId;
    }
    
    /**
     * @dev 배치 NFT 인증서 발행 (관리자 전용)
     * @param _to 소유자 주소 배열
     * @param _nameIds 이름 ID 배열
     * @param _tokenURIs 토큰 URI 배열
     * @param _imageURIs 인증서 이미지 URI 배열
     * @return 시작 토큰 ID와 끝 토큰 ID
     */
    function batchMintCertificates(
        address[] memory _to,
        uint256[] memory _nameIds,
        string[] memory _tokenURIs,
        string[] memory _imageURIs
    ) public onlyOwner returns (uint256, uint256) {
        // 배열 길이 검증
        require(_to.length > 0, "Empty batch");
        require(
            _to.length == _nameIds.length &&
            _to.length == _tokenURIs.length &&
            _to.length == _imageURIs.length,
            "Array length mismatch"
        );
        
        uint256 startTokenId = _tokenIds.current() + 1;
        uint256 count = 0;
        
        // 배치 발행
        for (uint i = 0; i < _to.length; i++) {
            // 유효성 검사
            if (_to[i] == address(0) || nameToToken[_nameIds[i]] != 0) {
                continue; // 유효하지 않은 데이터는 건너뜀
            }
            
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            
            // NFT 발행
            _mint(_to[i], newTokenId);
            _setTokenURI(newTokenId, _tokenURIs[i]);
            
            // 메타데이터 저장
            nftMetadata[newTokenId] = NFTMetadata({
                nameId: _nameIds[i],
                imageURI: _imageURIs[i],
                timestamp: block.timestamp
            });
            
            // 매핑 저장
            nameToToken[_nameIds[i]] = newTokenId;
            tokenToName[newTokenId] = _nameIds[i];
            
            // 개별 이벤트 발생
            emit CertificateMinted(newTokenId, _nameIds[i], _to[i]);
            
            count++;
        }
        
        uint256 endTokenId = _tokenIds.current();
        
        // 배치 발행 이벤트 발생
        emit BatchCertificatesMinted(startTokenId, endTokenId, count);
        
        return (startTokenId, endTokenId);
    }
    
    /**
     * @dev 이름 ID로 NFT ID 조회
     * @param _nameId 이름 ID
     * @return NFT ID
     */
    function getTokenIdByNameId(uint256 _nameId) public view returns (uint256) {
        uint256 tokenId = nameToToken[_nameId];
        require(tokenId != 0, "Certificate not minted for this name");
        return tokenId;
    }
    
    /**
     * @dev NFT ID로 이름 ID 조회
     * @param _tokenId NFT ID
     * @return 이름 ID
     */
    function getNameIdByTokenId(uint256 _tokenId) public view returns (uint256) {
        require(_exists(_tokenId), "Token does not exist");
        return tokenToName[_tokenId];
    }
    
    /**
     * @dev NFT 메타데이터 조회
     * @param _tokenId NFT ID
     * @return NFT 메타데이터
     */
    function getCertificateMetadata(uint256 _tokenId) public view returns (NFTMetadata memory) {
        require(_exists(_tokenId), "Token does not exist");
        return nftMetadata[_tokenId];
    }
    
    /**
     * @dev 총 발행된 NFT 수 조회
     * @return 총 NFT 수
     */
    function getTotalCertificates() public view returns (uint256) {
        return _tokenIds.current();
    }
}
