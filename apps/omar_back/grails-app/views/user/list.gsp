<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
  <meta name="layout" content="main"/>
  <title>AuthUser List</title>
</head>
<body>

<div class="nav">
  <span class="menuButton"><a class="home" href="${createLinkTo(dir: '')}">Home</a></span>
  <span class="menuButton"><g:link class="create" action="create">New AuthUser</g:link></span>
</div>

<div class="body">
  <h1>AuthUser List</h1>
  <g:if test="${flash.message}">
    <div class="message">${flash.message}</div>
  </g:if>
  <div class="list">
    <table>
      <thead>
      <tr>
        <g:sortableColumn property="id" title="Id"/>
        <g:sortableColumn property="username" title="Login Name"/>
        <g:sortableColumn property="email" title="E-Mail"/>
        <g:sortableColumn property="userRealName" title="Full Name"/>
        <g:sortableColumn property="enabled" title="Enabled"/>
        <g:sortableColumn property="description" title="Description"/>
      </tr>
      </thead>
      <tbody>
      <g:each in="${personList}" status="i" var="person">
        <tr class="${(i % 2) == 0 ? 'odd' : 'even'}">
          <td><g:link action="show" id="${person.id}">${fieldValue(bean: person, field: 'id')}</g:link></td>
          <td>${person.username?.encodeAsHTML()}</td>
          <td>${person.email?.encodeAsHTML()}</td>
          <td>${person.userRealName?.encodeAsHTML()}</td>
          <td>${person.enabled?.encodeAsHTML()}</td>
          <td>${person.description?.encodeAsHTML()}</td>
        </tr>
      </g:each>
      </tbody>
    </table>
  </div>

  <div class="paginateButtons">
    <g:paginate total="${AuthUser.count()}"/>
  </div>

</div>
</body>
</html>

