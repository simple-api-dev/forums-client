<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <title>Create Moderator</title>
    <link rel="stylesheet" href="resources/css/app.css">
</head>
<body>
<div class="container mt-3 mb-3">

    <h3>Create New Moderator</h3>
    <form action="http://127.0.0.1:8000/storeModerator" method="POST" enctype="multipart/form-data">
        @csrf

        <input type="hidden" name="id" value="{{$id}}">

        <div class="form-group">
            <label for="author_id">Author Id</label>
            <input type="text" class="form-control" name="author_id" id="author_id">
        </div>

        <div class="form-group">
            <label for="status">Status</label>
            <select class="form-control" name="status" id="status">
                <option value="Active">Active</option>
                <option value="Draft">Draft</option>
                <option value="Pending Review">Pending Review</option>
                <option value="Locked">Locked</option>
            </select>
        </div>

        <input type="reset" name="reset" value="Reset" class="btn btn-dark">
        <input type="submit" name="submit" value="Submit" class="btn btn-dark">

    </form>
</div>
</body>

</html>
