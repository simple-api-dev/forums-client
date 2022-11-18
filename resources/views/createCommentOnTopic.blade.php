<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>

<body>
<h3>Create Comment On Topic</h3>
<form action="{{getenv('FORUM_CLIENT')}}/storeComment" method="POST">
    @csrf

    <input type="hidden" name="id" value="{{$id}}">

    <div>
        <label for="body">Body</label>
        <input type="text" name="body" id="body">
    </div>

    <div>
        <label for="status">Status</label>
        <select name="status" id="status">
            <option value="Active">Active</option>
            <option value="Draft">Draft</option>
            <option value="Pending Review">Pending Review</option>
            <option value="Locked">Locked</option>
            <option value="Removed">Removed</option>
        </select>
    </div>

    <div>
        <label for="author_id">Author Id</label>
        <input type="text" name="author_id" id="author_id">
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
</body>
</html>
