<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="ManageUsers.aspx.cs" MasterPageFile="~/Site.Master" Inherits="WebApplication2.Account.ManageUsers" %>

<asp:Content runat="server" ID="BodyContent" ContentPlaceHolderID="MainContent">
  <h2><%: Title %></h2>
    <p class="text-danger">
        <asp:Literal runat="server" ID="ErrorMessage" />
    </p>
  <div>
    <p>Web User List</p>
    <asp:GridView ID="ManageUsersGrid" runat="server" AllowSorting="True" AutoGenerateColumns="False" DataKeyNames="Id" DataSourceID="ManageUsersQuery" CellPadding="10" CellSpacing="4" ForeColor="#333333" GridLines="None" OnSelectedIndexChanged="ManageUsersGrid_SelectedIndexChanged" CssClass="ManageUsersGrids">
      <AlternatingRowStyle BackColor="White" ForeColor="#284775" />
      <Columns>
        <asp:CommandField ShowDeleteButton="True" ShowEditButton="True" HeaderText="Command" />
        <asp:BoundField DataField="ProfileId" HeaderText="ProfileId" SortExpression="ProfileId" />
        <asp:BoundField DataField="Username" HeaderText="Username" SortExpression="Username" ReadOnly="True" />
        <asp:BoundField DataField="Id" HeaderText="Id" ReadOnly="True" SortExpression="Id" Visible="False" />
      </Columns>
      <EditRowStyle BackColor="#999999" />
      <FooterStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
      <HeaderStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
      <PagerStyle BackColor="#284775" ForeColor="White" HorizontalAlign="Center" />
      <RowStyle BackColor="#F7F6F3" ForeColor="#333333" />
      <SelectedRowStyle BackColor="#E2DED6" Font-Bold="True" ForeColor="#333333" />
      <SortedAscendingCellStyle BackColor="#E9E7E2" />
      <SortedAscendingHeaderStyle BackColor="#506C8C" />
      <SortedDescendingCellStyle BackColor="#FFFDF8" />
      <SortedDescendingHeaderStyle BackColor="#6F8DAE" />
    </asp:GridView>
    <br />
    <br />
    <p>Profile Id List</p>
    <asp:GridView ID="ProfileIdGrid" runat="server" AutoGenerateColumns="False" DataKeyNames="UserId" DataSourceID="ProfileIdQuery" CellPadding="10" CellSpacing="5" ForeColor="#333333" GridLines="None" CssClass="ManageUsersGrids">
      <AlternatingRowStyle BackColor="White" ForeColor="#284775" />
      <Columns>
        <asp:BoundField DataField="UserId" HeaderText="UserId" ReadOnly="True" SortExpression="UserId" />
        <asp:BoundField DataField="Name" HeaderText="Name" SortExpression="Name" />
        <asp:BoundField DataField="Client Name" HeaderText="Client Name" SortExpression="Client Name" />
      </Columns>
      <EditRowStyle BackColor="#999999" />
      <FooterStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
      <HeaderStyle BackColor="#5D7B9D" Font-Bold="True" ForeColor="White" />
      <PagerStyle BackColor="#284775" ForeColor="White" HorizontalAlign="Center" />
      <RowStyle BackColor="#F7F6F3" ForeColor="#333333" />
      <SelectedRowStyle BackColor="#E2DED6" Font-Bold="True" ForeColor="#333333" />
      <SortedAscendingCellStyle BackColor="#E9E7E2" />
      <SortedAscendingHeaderStyle BackColor="#506C8C" />
      <SortedDescendingCellStyle BackColor="#FFFDF8" />
      <SortedDescendingHeaderStyle BackColor="#6F8DAE" />
    </asp:GridView>
    <asp:SqlDataSource ID="ProfileIdQuery" runat="server" ConnectionString="<%$ ConnectionStrings:DefaultConnection %>" SelectCommand="SELECT tblUsers.UserId, tblUsers.Name, tblClients.Name AS [Client Name] FROM tblUsers INNER JOIN tblClients ON tblUsers.ClientId = tblClients.ClientId"></asp:SqlDataSource>
    <asp:SqlDataSource ID="ManageUsersQuery" runat="server" ConnectionString="<%$ ConnectionStrings:DefaultConnection %>" DeleteCommand="DELETE FROM [ASPWebUsers] WHERE [Id] = @Id;
Delete from [ASPNetUsers] where [Id] = @Id;" InsertCommand="INSERT INTO [ASPWebUsers] ([ProfileId], [Username], [Id]) VALUES (@ProfileId, @Username, @Id)" SelectCommand="SELECT [ProfileId], [Username], [Id] FROM [ASPWebUsers]" UpdateCommand="UPDATE [ASPWebUsers] SET [ProfileId] = @ProfileId WHERE [Id] = @Id">
      <DeleteParameters>
        <asp:Parameter Name="Id" Type="String" />
      </DeleteParameters>
      <InsertParameters>
        <asp:Parameter Name="ProfileId" Type="Int32" />
        <asp:Parameter Name="Username" Type="String" />
        <asp:Parameter Name="Id" Type="String" />
      </InsertParameters>
      <UpdateParameters>
        <asp:Parameter Name="ProfileId" Type="Int32" />
        <asp:Parameter Name="Username" Type="String" />
        <asp:Parameter Name="Id" Type="String" />
      </UpdateParameters>
    </asp:SqlDataSource>
    <br />
    <br />
    <a href="../Default.aspx">Back</a>
  </div>
</asp:Content>
