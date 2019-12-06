<%@ Page Title="Contact" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Contact.aspx.cs" Inherits="WebApplication2.Contact" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
    <h2><%: Title %>.</h2>
    <h3>Aware360 Ltd.</h3>
    <address>
        Unit 250 1201 Glenmore Trail SW<br />
        Calgary AB, T2V 4Y8<br />
        <abbr title="Phone">P:</abbr>
        403.252.5007
    </address>

    <address>
        <strong>Support:</strong>   <a href="mailto:support@aware360.com">support@aware360.com</a><br />
        <strong>Marketing:</strong> <a href="mailto:sales@aware360.com">sales@aware360.com</a>
    </address>
</asp:Content>
