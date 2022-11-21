<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>

<body>
<h3>Create New Forum Rule</h3>
<form action="{{getenv('FORUM_CLIENT')}}/storeRule" method="POST">
    @csrf

    <input type="hidden" name="forum_id" value="{{$forum_id}}">
    <input type="hidden" name="forum_slug" value="{{$forum_slug}}">

    <div>
        <label for="body">Body</label>
        <input type="text" name="body" id="body">
    </div>

    <div>
        <label for="status">Status</label>
        <select name="status" id="status">
            <option value="Active">Active</option>
            <option value="Disabled">Disabled</option>
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
