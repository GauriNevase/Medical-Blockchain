// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Agent {
    
    struct patient {
        string name;
        uint age;
        address[] doctorAccessList;
        uint[] diagnosis;
        string record;
    }
    
    struct doctor {
        string name;
        uint age;
        address[] patientAccessList;
    }

    uint creditPool;

    address[] public patientList;
    address[] public doctorList;

    mapping (address => patient) patientInfo;
    mapping (address => doctor) doctorInfo;
    mapping (address => address) Empty;

    function add_agent(string memory _name, uint _age, uint _designation, string memory _hash) public returns(string memory) {
        address addr = msg.sender;

        if (_designation == 0) {
            patient memory p;
            p.name = _name;
            p.age = _age;
            p.record = _hash;
            patientInfo[addr] = p;
            patientList.push(addr);
            return _name;
        } else if (_designation == 1) {
            doctorInfo[addr].name = _name;
            doctorInfo[addr].age = _age;
            doctorList.push(addr);
            return _name;
        } else {
            revert("Invalid designation");
        }
    }

    function get_patient(address addr) view public returns (string memory, uint, uint[] memory, address, string memory) {
        return (
            patientInfo[addr].name,
            patientInfo[addr].age,
            patientInfo[addr].diagnosis,
            Empty[addr],
            patientInfo[addr].record
        );
    }

    function get_doctor(address addr) view public returns (string memory, uint) {
        return (doctorInfo[addr].name, doctorInfo[addr].age);
    }

    function get_patient_doctor_name(address paddr, address daddr) view public returns (string memory, string memory) {
        return (patientInfo[paddr].name, doctorInfo[daddr].name);
    }

    function permit_access(address addr) public payable {
        require(msg.value == 2 ether, "Access requires exactly 2 ether");
        creditPool += 2 ether;

        doctorInfo[addr].patientAccessList.push(msg.sender);
        patientInfo[msg.sender].doctorAccessList.push(addr);
    }

    function insurance_claim(address paddr, uint _diagnosis, string memory _hash) public {
        bool patientFound = false;

        for (uint i = 0; i < doctorInfo[msg.sender].patientAccessList.length; i++) {
            if (doctorInfo[msg.sender].patientAccessList[i] == paddr) {
                (bool sent, ) = msg.sender.call{value: 2 ether}("");
                require(sent, "Transfer failed");
                creditPool -= 2 ether;
                patientFound = true;
                break;
            }
        }

        if (patientFound) {
            set_hash(paddr, _hash);
            remove_patient(paddr, msg.sender);
        } else {
            revert("Patient not found in access list");
        }

        for (uint j = 0; j < patientInfo[paddr].diagnosis.length; j++) {
            if (patientInfo[paddr].diagnosis[j] == _diagnosis) {
                break;
            }
        }
    }

    function remove_element_in_array(address[] storage Array, address addr) internal {
        bool found = false;
        uint index;

        for (uint i = 0; i < Array.length; i++) {
            if (Array[i] == addr) {
                found = true;
                index = i;
                break;
            }
        }

        if (!found) revert("Element not found");

        Array[index] = Array[Array.length - 1];
        Array.pop();
    }

    function remove_patient(address paddr, address daddr) public {
        remove_element_in_array(doctorInfo[daddr].patientAccessList, paddr);
        remove_element_in_array(patientInfo[paddr].doctorAccessList, daddr);
    }

    function get_accessed_doctorlist_for_patient(address addr) public view returns (address[] memory) {
        return patientInfo[addr].doctorAccessList;
    }

    function get_accessed_patientlist_for_doctor(address addr) public view returns (address[] memory) {
        return doctorInfo[addr].patientAccessList;
    }

    function revoke_access(address daddr) public {
        remove_patient(msg.sender, daddr);
        (bool sent, ) = msg.sender.call{value: 2 ether}("");
        require(sent, "Revoke refund failed");
        creditPool -= 2 ether;
    }

    function get_patient_list() public view returns (address[] memory) {
        return patientList;
    }

    function get_doctor_list() public view returns (address[] memory) {
        return doctorList;
    }

    function get_hash(address paddr) public view returns (string memory) {
        return patientInfo[paddr].record;
    }

    function set_hash(address paddr, string memory _hash) internal {
        patientInfo[paddr].record = _hash;
    }
}
