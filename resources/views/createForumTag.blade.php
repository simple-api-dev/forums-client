<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>

<body>
<h3>Create Forum Tag</h3>
<form action="{{getenv('FORUM_CLIENT')}}/storeForumTag" method="POST">
    @csrf

    <input type="hidden" name="id" value="{{$id}}">

    <div>
        <label for="name">Name</label>
        <input type="text" name="name" id="name">
    </div>

    <div>
        <label for="status">Status</label>
        <select name="status" id="status">
            <option value="Active">Active</option>
            <option value="Locked">Locked</option>
        </select>
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
</body>
</html>
