
## Actor (use case) diagram

```mermaid
flowchart LR
  Guest((Guest))
  Client((Client / Driver))
  Admin((Admin))
  Operator((Vehicle Operator))

  subgraph System[Loading vehicle booking system]
    UC1([Sign up])
    UC2([Login])
    UC3([Book loading vehicle])
    UC4([List vehicle with remaining capacity])
    UC5([View previous bookings])
    UC6([Cancel booking])
    UC7([Show all bookings - admin only])
    UC8([View assigned booking])
  end

  Guest --> UC1
  Guest --> UC2
  Client --> UC2
  Client --> UC3
  Client --> UC4
  Client --> UC5
  Client --> UC6
  Admin --> UC2
  Admin --> UC3
  Admin --> UC4
  Admin --> UC5
  Admin --> UC6
  Admin --> UC7
  Operator --> UC2
  Operator --> UC8

  classDef actor fill:#E6F1FB,stroke:#185FA5,color:#0C447C;
  classDef common fill:#EEEDFE,stroke:#534AB7,color:#3C3489;
  classDef adminOnly fill:#FAEEDA,stroke:#854F0B,color:#633806;
  classDef opOnly fill:#E1F5EE,stroke:#0F6E56,color:#085041;

  class Guest,Client,Admin,Operator actor;
  class UC1,UC2,UC3,UC4,UC5,UC6 common;
  class UC7 adminOnly;
  class UC8 opOnly;
```


## Activity (flow) diagram

```mermaid
flowchart TD
  Start([Start]) --> Menu[Show menu: Login or Sign up]
  Menu --> Choice{Login or sign up?}

  Choice -- Sign up --> SU1[Enter office address, name, role, password]
  SU1 --> SU2{Role = Driver?}
  SU2 -- Yes --> SU3[Select vehicle from available list]
  SU2 -- No --> Login[Login]
  SU3 --> Login

  Choice -- Login --> Login

  Login --> RoleCheck{Check role}
  RoleCheck -- Admin --> AdminMenu[All client options + Show bookings]
  RoleCheck -- Vehicle Operator --> OpMenu[View assigned booking only]
  RoleCheck -- Client / Driver --> ClientMenu[Book vehicle, list capacity, view bookings, cancel booking]

  AdminMenu --> BookFlow[Book loading vehicle]
  ClientMenu --> BookFlow

  BookFlow --> B1[Enter pallets]
  B1 --> B2[Enter destination]
  B2 --> B3[Enter type of goods]
  B3 --> B4[Enter pickup time range]
  B4 --> B5[Enter delivery time range]
  B5 --> B6{List for remaining capacity?}
  B6 --> B7[Check vehicles with matching remaining capacity]
  B7 --> B8{Match found?}
  B8 -- Yes --> B9[Show option: book this vehicle, price and ETA - or book new vehicle]
  B8 -- No --> B10[Proceed to book new vehicle]
  B9 --> Confirm[Confirmation of booking]
  B10 --> Confirm
  Confirm --> End([End])

  classDef terminal fill:#EAF3DE,stroke:#3B6D11,color:#27500A;
  classDef decision fill:#FAEEDA,stroke:#854F0B,color:#633806;
  classDef structural fill:#F1EFE8,stroke:#5F5E5A,color:#444441;
  classDef signup fill:#EEEDFE,stroke:#534AB7,color:#3C3489;
  classDef loginPath fill:#E6F1FB,stroke:#185FA5,color:#0C447C;
  classDef adminPath fill:#FBEAF0,stroke:#993556,color:#72243E;
  classDef opPath fill:#E1F5EE,stroke:#0F6E56,color:#085041;
  classDef clientPath fill:#FAECE7,stroke:#993C1D,color:#712B13;
  classDef shared fill:#F1EFE8,stroke:#5F5E5A,color:#444441;

  class Start,End terminal;
  class Choice,SU2,B6,B8,RoleCheck decision;
  class Menu structural;
  class SU1,SU3 signup;
  class Login loginPath;
  class AdminMenu adminPath;
  class OpMenu opPath;
  class ClientMenu clientPath;
  class BookFlow,B1,B2,B3,B4,B5,B7,B9,B10,Confirm shared;

  linkStyle 0,1 stroke:#888780,stroke-width:1.5px;
  linkStyle 2,3,4,5,6 stroke:#7F77DD,stroke-width:2px;
  linkStyle 7,8 stroke:#378ADD,stroke-width:2px;
  linkStyle 9,12 stroke:#D4537E,stroke-width:2px;
  linkStyle 10 stroke:#5DCAA5,stroke-width:2px;
  linkStyle 11,13 stroke:#D85A30,stroke-width:2px;
  linkStyle 14,15,16,17,18,19,20,21 stroke:#888780,stroke-width:1.5px;
  linkStyle 22,23 stroke:#EF9F27,stroke-width:2px;
  linkStyle 24,25,26 stroke:#888780,stroke-width:1.5px;
```
