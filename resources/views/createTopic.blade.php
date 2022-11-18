<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Forum-Client</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>

<body>
<h3>Create New Topic</h3>
<form action="{{getenv('FORUM_CLIENT')}}/storeTopic" method="POST">
    @csrf

    <input type="hidden" name="id" value="{{$id}}">

    <div>
        <label for="title">Title</label>
        <input type="text" name="title" id="title">
    </div>

    <div>
        <label for="body">Body</label>
        <input type="text" name="body" id="body">
    </div>

    <div>
        <label for="type">Type</label>
        <select name="type" id="type">
            <option value="Post">Post</option>
            <option value="Video">Video</option>
            <option value="Url">Url</option>
            <option value="Image">Image</option>
        </select>
    </div>

    <div>
        <label for="status">Status</label>
        <select name="status" id="status">
            <option value="Active">Active</option>
            <option value="Draft">Draft</option>
            <option value="Pending Review">Pending Review</option>
            <option value="Locked">Locked</option>
        </select>
    </div>

    <div>
        <label for="author_id">Author Id</label>
        <input type="text" name="author_id" id="author_id">
    </div>

    <div>
        <label for="tags">Tags</label>
        <input type="text" name="tags" id="tags">
    </div>

    <input type="reset" name="reset" value="Reset">
    <input type="submit" name="submit" value="Submit">
</form>
</body>
</html>
