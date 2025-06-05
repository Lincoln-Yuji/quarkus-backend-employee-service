package services;

import jakarta.enterprise.context.ApplicationScoped;

import jakarta.transaction.Transactional;

import java.util.List;
import entities.EmployeeEntity;

@ApplicationScoped
public class EmployeeService
{
    @Transactional
    public EmployeeEntity createUser(EmployeeEntity employee) {
        employee.persist();
        return employee;
    }

    public List<EmployeeEntity> findAll(int pageNumber, int pageSize) {
        return EmployeeEntity.findAll().page(pageNumber, pageSize).list();
    }

    public EmployeeEntity findById(String id) {
        List<EmployeeEntity> employeesFound = EmployeeEntity.find("id = ?1", id).list();
        if (employeesFound.size() == 1) {
            return employeesFound.get(0);
        }
        return null;
    }

    @Transactional
    public EmployeeEntity updateUser(EmployeeEntity employeeEntity) {
        EmployeeEntity updatedEmployeeEntity = findById(employeeEntity.id);

        // Do not continue if the Employee ID was not found
        if (updatedEmployeeEntity == null)
            return null;

        // Only update the fields that are not null in the argument's entity
        if (employeeEntity.name != null) {
            updatedEmployeeEntity.name = employeeEntity.name;
        }
        if (employeeEntity.email != null) {
            updatedEmployeeEntity.email = employeeEntity.email;
        }
        return updatedEmployeeEntity;
    }

    @Transactional
    public long deleteUser(String userId) {
        return EmployeeEntity.delete("id", userId);
    }
}
