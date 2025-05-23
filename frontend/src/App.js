import React, { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import './App.css';
import DaJeumNamingABI from './artifacts/contracts/DaJeumNaming.sol/DaJeumNaming.json';
import DaJeumNFTABI from './artifacts/contracts/DaJeumNFT.sol/DaJeumNFT.json';
import DaJeumTokenABI from './artifacts/contracts/DaJeumToken.sol/DaJeumToken.json';

// 테스트넷 컨트랙트 주소
const namingContractAddress = "0x1234567890123456789012345678901234567890"; // 예시 주소
const nftContractAddress = "0x0987654321098765432109876543210987654321"; // 예시 주소
const tokenContractAddress = "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd"; // 예시 주소

function App() {
  const [account, setAccount] = useState("");
  const [isConnected, setIsConnected] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [successMessage, setSuccessMessage] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  
  // 이름 등록 폼 상태
  const [fullName, setFullName] = useState("");
  const [birthYear, setBirthYear] = useState("");
  const [birthMonth, setBirthMonth] = useState("");
  const [birthDay, setBirthDay] = useState("");
  const [gender, setGender] = useState("여");
  
  // 지갑 연결 함수
  const connectWallet = async () => {
    try {
      setIsLoading(true);
      setErrorMessage("");
      
      if (window.ethereum) {
        const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
        setAccount(accounts[0]);
        setIsConnected(true);
        setSuccessMessage("지갑이 연결되었습니다!");
      } else {
        setErrorMessage("MetaMask를 설치해주세요!");
      }
    } catch (error) {
      console.error("지갑 연결 오류:", error);
      setErrorMessage("지갑 연결에 실패했습니다. 다시 시도해주세요.");
    } finally {
      setIsLoading(false);
    }
  };
  
  // 이름 등록 함수
  const registerName = async (e) => {
    e.preventDefault();
    
    if (!isConnected) {
      setErrorMessage("먼저 지갑을 연결해주세요!");
      return;
    }
    
    if (!fullName || !birthYear || !birthMonth || !birthDay) {
      setErrorMessage("모든 필드를 입력해주세요!");
      return;
    }
    
    try {
      setIsLoading(true);
      setErrorMessage("");
      setSuccessMessage("");
      
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const namingContract = new ethers.Contract(
        namingContractAddress,
        DaJeumNamingABI.abi,
        signer
      );
      
      console.log("계약 호출 시작...");
      const tx = await namingContract.registerName(
        fullName,
        parseInt(birthYear),
        parseInt(birthMonth),
        parseInt(birthDay),
        gender
      );
      
      console.log("트랜잭션 전송됨:", tx.hash);
      setSuccessMessage("트랜잭션이 전송되었습니다. 처리 중...");
      
      await tx.wait();
      console.log("트랜잭션 완료!");
      setSuccessMessage("이름이 성공적으로 등록되었습니다!");
      
      // 폼 초기화
      setFullName("");
      setBirthYear("");
      setBirthMonth("");
      setBirthDay("");
    } catch (error) {
      console.error("이름 등록 오류:", error);
      setErrorMessage("이름 등록에 실패했습니다: " + (error.message || "알 수 없는 오류"));
    } finally {
      setIsLoading(false);
    }
  };
  
  return (
    <div className="app">
      <header className="app-header">
        <h1>다지음 작명 블록체인 서비스</h1>
        {!isConnected ? (
          <button onClick={connectWallet} disabled={isLoading} className="connect-button">
            {isLoading ? "연결 중..." : "지갑 연결"}
          </button>
        ) : (
          <div className="account-info">
            <span>연결된 계정: {account.substring(0, 6)}...{account.substring(account.length - 4)}</span>
          </div>
        )}
      </header>
      
      <main className="app-main">
        {errorMessage && <div className="error-message">{errorMessage}</div>}
        {successMessage && <div className="success-message">{successMessage}</div>}
        
        <section className="register-section">
          <h2>이름 등록</h2>
          <form onSubmit={registerName} className="register-form">
            <div className="form-group">
              <label>이름 (성+이름)</label>
              <input 
                type="text" 
                value={fullName} 
                onChange={(e) => setFullName(e.target.value)}
                placeholder="예: 홍길동"
                required
              />
            </div>
            
            <div className="form-group">
              <label>출생년도</label>
              <input 
                type="number" 
                value={birthYear} 
                onChange={(e) => setBirthYear(e.target.value)}
                placeholder="예: 1990"
                required
              />
            </div>
            
            <div className="form-group">
              <label>출생월</label>
              <input 
                type="number" 
                value={birthMonth} 
                onChange={(e) => setBirthMonth(e.target.value)}
                placeholder="예: 12"
                min="1"
                max="12"
                required
              />
            </div>
            
            <div className="form-group">
              <label>출생일</label>
              <input 
                type="number" 
                value={birthDay} 
                onChange={(e) => setBirthDay(e.target.value)}
                placeholder="예: 25"
                min="1"
                max="31"
                required
              />
            </div>
            
            <div className="form-group">
              <label>성별</label>
              <select value={gender} onChange={(e) => setGender(e.target.value)}>
                <option value="여">여</option>
                <option value="남">남</option>
              </select>
            </div>
            
            <button type="submit" disabled={isLoading || !isConnected} className="submit-button">
              {isLoading ? "처리 중..." : "이름 등록"}
            </button>
          </form>
        </section>
      </main>
      
      <footer className="app-footer">
        <p>© 2025 다지음 작명 블록체인 서비스 | 아발란체 프로토콜 기반</p>
      </footer>
    </div>
  );
}

export default App;
