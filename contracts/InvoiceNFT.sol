// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract InvoiceNFT is ERC721URIStorage {
    uint256 public nextInvoiceId;
    address public admin;

    enum Status {
        Draft,
        Pending,
        Approved,
        LoanBefore,
        LoanStarted,
        LoanDone,
        Paid,
        Rejected
    }

    struct InvoiceData {
        address issuer;      // Borrower
        address recipient;   // admin
        uint256 amount;      // loan amount (usually < invoice)
        uint256 dueDate;     // invoice due date
        Status status;
        string metadataURI;  // invoice image/IPFS hash
    }

    mapping(uint256 => InvoiceData) public invoices;
    mapping(address => uint256[]) public userInvoices;

    event InvoiceMinted(uint256 indexed invoiceId, address issuer);
    event InvoiceStatusChanged(uint256 indexed invoiceId, Status newStatus);

    constructor(address _admin) ERC721("RealWorldInvoice", "RWI") {
        require(_admin != address(0), "Invalid admin");
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    /// @notice Borrower가 Invoice NFT 업로드
    function mintInvoice(
        address recipient,
        uint256 amount,
        uint256 dueDate,
        string calldata uri
    ) external returns (uint256) {
        uint256 invoiceId = nextInvoiceId++;
        _safeMint(msg.sender, invoiceId);
        _setTokenURI(invoiceId, uri);

        invoices[invoiceId] = InvoiceData({
            issuer: msg.sender,
            recipient: recipient,
            amount: amount,
            dueDate: dueDate,
            status: Status.Pending,
            metadataURI: uri
        });

        userInvoices[msg.sender].push(invoiceId);

        emit InvoiceMinted(invoiceId, msg.sender);
        return invoiceId;
    }

    /// @notice Admin이 상태 변경
    function setInvoiceStatus(uint256 invoiceId, Status newStatus) external onlyAdmin {
        invoices[invoiceId].status = newStatus;
        emit InvoiceStatusChanged(invoiceId, newStatus);
    }

    /// @notice 전체 정보 조회
    function getInvoice(uint256 invoiceId) external view returns (InvoiceData memory) {
        return invoices[invoiceId];
    }

    /// @notice 내가 발행한 모든 인보이스 조회
    function getMyInvoices() external view returns (InvoiceData[] memory) {
        uint256[] storage ids = userInvoices[msg.sender];
        InvoiceData[] memory result = new InvoiceData[](ids.length);

        for (uint256 i = 0; i < ids.length; i++) {
            result[i] = invoices[ids[i]];
        }

        return result;
    }

    /// @notice Admin 변경 (선택 사항)
    function updateAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin");
        admin = newAdmin;
    }
}
