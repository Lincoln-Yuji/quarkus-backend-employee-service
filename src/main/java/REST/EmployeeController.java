package REST;

import java.util.List;

import entities.EmployeeEntity;
import services.EmployeeService;

import jakarta.inject.Inject;
import jakarta.persistence.PersistenceException;
import jakarta.validation.ConstraintViolationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.DefaultValue;
import jakarta.ws.rs.DELETE;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.PUT;

@Path("/employees")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class EmployeeController
{
    @Inject
    private EmployeeService employeeService;

    @POST
    public Response createUser(EmployeeEntity employee) {
        try {
            EmployeeEntity created = employeeService.createUser(employee);
            return Response.status(Response.Status.CREATED).entity(created).build();
        }
        catch (PersistenceException e) {
            return Response.status(Response.Status.BAD_REQUEST).entity("Database error: " + e.getMessage()).build();
        }
        catch (ConstraintViolationException e) {
            return Response.status(Response.Status.CONFLICT).entity("Constraint violation: " + e.getMessage()).build();
        }
    }

    @GET
    public Response findAllEmployees(@QueryParam("pageNumber") @DefaultValue("0") Integer pageNumber, @QueryParam("pageSize") @DefaultValue("5") Integer pageSize) {
        List<EmployeeEntity> employees = employeeService.findAll(pageNumber, pageSize);
        return Response.ok(employees).build();
    }

    @GET
    @Path("/{id}")
    public Response findEmployeeById(@PathParam("id") String employeeId) {
        EmployeeEntity employee = employeeService.findById(employeeId);
        if (employee != null) {
            return Response.ok(employee).build();
        }
        return Response.status(Response.Status.NOT_FOUND).entity("Employee with code " + employeeId + " not found!").build();
    }

    @PUT
    public Response updateUser(EmployeeEntity employeeEntity) {
        EmployeeEntity updatedEntity = employeeService.updateUser(employeeEntity);
        if (updatedEntity != null) {
            return Response.ok(updatedEntity).build();
        }
        return Response.status(Response.Status.NOT_FOUND).entity("Employee with code " + employeeEntity.id + " not found!").build();
    }

    @DELETE
    @Path("/{id}")
    public Response deleteUser(@PathParam("id") String employeeId) {
        if (employeeService.deleteUser(employeeId) > 0) {
            return Response.ok("Employee " + employeeId + " deleted from the database!").build();
        }
        return Response.status(Response.Status.NOT_FOUND).entity("Employee with code " + employeeId + " not found!").build();
    }
}
