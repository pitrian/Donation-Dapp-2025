// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DonationDApp {
    // --- CẤU HÌNH ĐA CHỦ SỞ HỮU (MULTI-SIG) ---
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredApprovals; // Số lượng phiếu đồng thuận cần thiết

    // Cấu trúc một Dự án
    struct Campaign {
        uint256 id;
        address creator;
        string title;
        string description;
        string image;
        uint256 target;
        uint256 raised;
        uint256 currentBalance;
        bool isOpen;
    }

    struct Donation {
        uint256 campaignId;
        address donor;
        uint256 amount;
        string message;
        uint256 timestamp;
    }

    // Cấu trúc Yêu cầu Rút tiền (Thay đổi lớn ở đây)
    struct WithdrawalRequest {
        uint256 id;             // ID của yêu cầu
        address payable to;     // Người nhận
        uint256 amount;         // Số tiền
        string reason;          // Lý do
        string proof;           // Minh chứng
        uint256 timestamp;      // Thời gian tạo
        uint256 approvalCount;  // Số người đã duyệt
        bool executed;          // Đã chuyển tiền chưa?
    }

    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => WithdrawalRequest[]) public campaignWithdrawals; 
    
    // Mapping lưu trạng thái: CampaignID -> WithdrawalIndex -> OwnerAddress -> Đã duyệt chưa?
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public approvals;

    uint256 public campaignCount = 0;
    Donation[] public donations;

    // Sự kiện
    event CampaignCreated(uint256 id, string title, uint256 target);
    event NewDonation(uint256 indexed campaignId, address indexed donor, uint256 amount, string message);
    event WithdrawalRequested(uint256 indexed campaignId, uint256 withdrawalId, address to, uint256 amount, string reason);
    event WithdrawalApproved(uint256 indexed campaignId, uint256 withdrawalId, address approver);
    event FundsWithdrawn(uint256 indexed campaignId, address indexed to, uint256 amount, uint256 timestamp);
    event ProofAdded(uint256 indexed campaignId, uint256 withdrawalIndex, string proof);

    // Constructor nhận danh sách chủ sở hữu
    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(_owners.length > 0, "Can it nhat 1 chu so huu");
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, "So phieu khong hop le");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Dia chi khong hop le");
            require(!isOwner[owner], "Chu so huu bi trung lap");

            isOwner[owner] = true;
            owners.push(owner);
        }
        requiredApprovals = _requiredApprovals;
    }

    modifier onlyOwners() {
        require(isOwner[msg.sender], "Chi chu so huu moi co quyen");
        _;
    }

    // 1. TẠO DỰ ÁN MỚI
    function createCampaign(string memory _title, string memory _desc, string memory _image, uint256 _target) public onlyOwners {
        campaigns[campaignCount] = Campaign({
            id: campaignCount,
            creator: msg.sender,
            title: _title,
            description: _desc,
            image: _image,
            target: _target,
            raised: 0,
            currentBalance: 0,
            isOpen: true
        });

        emit CampaignCreated(campaignCount, _title, _target);
        campaignCount++;
    }

    // 2. QUYÊN GÓP
    function donateToCampaign(uint256 _id, string memory _message) public payable {
        require(msg.value > 0, "So tien phai > 0");
        require(_id < campaignCount, "Du an khong ton tai");
        require(campaigns[_id].isOpen, "Du an da dong");

        campaigns[_id].raised += msg.value;
        campaigns[_id].currentBalance += msg.value;

        donations.push(Donation(_id, msg.sender, msg.value, _message, block.timestamp));
        emit NewDonation(_id, msg.sender, msg.value, _message);
    }

    // 3. TẠO YÊU CẦU RÚT TIỀN (Bước 1: Tạo Request)
    function createWithdrawRequest(uint256 _id, address payable _to, uint256 _amount, string memory _reason) public onlyOwners {
        require(campaigns[_id].currentBalance >= _amount, "Khong du so du");

        uint256 withdrawalId = campaignWithdrawals[_id].length;

        campaignWithdrawals[_id].push(WithdrawalRequest({
            id: withdrawalId,
            to: _to,
            amount: _amount,
            reason: _reason,
            proof: "",
            timestamp: block.timestamp,
            approvalCount: 0,
            executed: false
        }));

        // Tự động duyệt cho người tạo yêu cầu
        _approveWithdrawal(_id, withdrawalId);

        emit WithdrawalRequested(_id, withdrawalId, _to, _amount, _reason);
    }

    // 4. DUYỆT YÊU CẦU RÚT TIỀN (Bước 2: Các owner khác duyệt)
    function approveWithdrawRequest(uint256 _campaignId, uint256 _withdrawalId) public onlyOwners {
        _approveWithdrawal(_campaignId, _withdrawalId);
    }

    // Hàm nội bộ xử lý logic duyệt và tự động chuyển tiền nếu đủ phiếu
    function _approveWithdrawal(uint256 _campaignId, uint256 _withdrawalId) internal {
        WithdrawalRequest storage request = campaignWithdrawals[_campaignId][_withdrawalId];
        require(!request.executed, "Yeu cau da duoc thuc thi roi");
        require(!approvals[_campaignId][_withdrawalId][msg.sender], "Ban da duyet yeu cau nay roi");

        approvals[_campaignId][_withdrawalId][msg.sender] = true;
        request.approvalCount++;
        
        emit WithdrawalApproved(_campaignId, _withdrawalId, msg.sender);

        // Nếu đủ phiếu -> Thực hiện chuyển tiền luôn
        if (request.approvalCount >= requiredApprovals) {
            executeWithdrawal(_campaignId, _withdrawalId);
        }
    }

    // Hàm thực thi chuyển tiền (Internal)
    function executeWithdrawal(uint256 _campaignId, uint256 _withdrawalId) internal {
        WithdrawalRequest storage request = campaignWithdrawals[_campaignId][_withdrawalId];
        Campaign storage campaign = campaigns[_campaignId];

        require(campaign.currentBalance >= request.amount, "So du khong du (trong luc cho duyet)");
        require(!request.executed, "Da thuc thi");

        request.executed = true;
        campaign.currentBalance -= request.amount;

        (bool success, ) = request.to.call{value: request.amount}("");
        require(success, "Chuyen tien that bai");

        emit FundsWithdrawn(_campaignId, request.to, request.amount, block.timestamp);
    }

    // 5. CẬP NHẬT MINH CHỨNG
    function addProofToWithdrawal(uint256 _campaignId, uint256 _withdrawalIndex, string memory _proof) public onlyOwners {
        require(_withdrawalIndex < campaignWithdrawals[_campaignId].length, "Giao dich khong ton tai");
        require(campaignWithdrawals[_campaignId][_withdrawalIndex].executed, "Giao dich chua duoc thuc thi");
        
        campaignWithdrawals[_campaignId][_withdrawalIndex].proof = _proof;
        emit ProofAdded(_campaignId, _withdrawalIndex, _proof);
    }

    // 6. ĐÓNG/MỞ DỰ ÁN
    function toggleCampaignStatus(uint256 _id) public onlyOwners {
        campaigns[_id].isOpen = !campaigns[_id].isOpen;
    }

    // --- CÁC HÀM VIEW HELPER ---
    
    function getCampaignWithdrawals(uint256 _campaignId) public view returns (WithdrawalRequest[] memory) {
        return campaignWithdrawals[_campaignId];
    }

    function getAllDonations() public view returns (Donation[] memory) {
        return donations;
    }

    // Kiểm tra xem user đã duyệt request này chưa
    function hasApproved(uint256 _campaignId, uint256 _withdrawalId, address _user) public view returns (bool) {
        return approvals[_campaignId][_withdrawalId][_user];
    }
}